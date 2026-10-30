use std::path::Path;
use std::process::Command;

fn run(cmd: &str, args: &[&str]) -> Option<String> {
    Command::new(cmd)
        .args(args)
        .output()
        .ok()
        .filter(|o| o.status.success())
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
}

fn rerun_if_git_path_changed(git_path: &str) {
    if let Some(path) = run(
        "git",
        &[
            "rev-parse",
            "--path-format=absolute",
            "--git-path",
            git_path,
        ],
    ) && Path::new(&path).exists()
    {
        println!("cargo:rerun-if-changed={path}");
    }
}

fn main() {
    let commit =
        run("git", &["rev-parse", "--short", "HEAD"]).unwrap_or_else(|| "unknown".to_string());
    let date = run("date", &["-u", "+%Y-%m-%d"]).unwrap_or_else(|| "unknown".to_string());

    println!("cargo:rustc-env=BUILD_COMMIT={commit}");
    println!("cargo:rustc-env=BUILD_DATE={date}");

    rerun_if_git_path_changed("HEAD");
    if let Some(branch) = run("git", &["symbolic-ref", "-q", "HEAD"]) {
        rerun_if_git_path_changed(&branch);
    }
}
