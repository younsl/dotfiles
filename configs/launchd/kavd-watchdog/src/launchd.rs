use std::process::{ExitStatus, Output};

use tokio::process::Command;

const LAUNCHCTL: &str = "/bin/launchctl";
const SERVICE_NOT_FOUND: i32 = 113;

#[derive(Debug, thiserror::Error)]
pub enum LaunchdError {
    #[error("failed to run {LAUNCHCTL}: {0}")]
    Spawn(std::io::Error),
    #[error("launchctl {action} {service} exited with {status}: {stderr}")]
    Failed {
        action: &'static str,
        service: String,
        status: ExitStatus,
        stderr: String,
    },
    #[error("launchctl print {service} reported an invalid pid: {value}")]
    InvalidPid { service: String, value: String },
}

async fn launchctl(action: &'static str, args: &[&str]) -> Result<Output, LaunchdError> {
    Command::new(LAUNCHCTL)
        .arg(action)
        .args(args)
        .output()
        .await
        .map_err(LaunchdError::Spawn)
}

fn failed(action: &'static str, service: &str, output: &Output) -> LaunchdError {
    LaunchdError::Failed {
        action,
        service: service.to_owned(),
        status: output.status,
        stderr: String::from_utf8_lossy(&output.stderr).trim().to_owned(),
    }
}

pub async fn service_pid(service: &str) -> Result<Option<u32>, LaunchdError> {
    let output = launchctl("print", &[service]).await?;
    if output.status.code() == Some(SERVICE_NOT_FOUND) {
        return Ok(None);
    }
    if !output.status.success() {
        return Err(failed("print", service, &output));
    }

    parse_pid(&String::from_utf8_lossy(&output.stdout)).map_err(|value| LaunchdError::InvalidPid {
        service: service.to_owned(),
        value,
    })
}

fn parse_pid(print: &str) -> Result<Option<u32>, String> {
    print
        .lines()
        .find_map(|line| line.strip_prefix("\tpid = "))
        .map(|value| value.trim().parse().map_err(|_| value.trim().to_owned()))
        .transpose()
}

pub async fn kickstart(service: &str) -> Result<(), LaunchdError> {
    let output = launchctl("kickstart", &["-k", service]).await?;
    if output.status.success() {
        return Ok(());
    }
    Err(failed("kickstart", service, &output))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_top_level_pid() {
        let print = "system/com.example.daemon = {\n\tactive count = 1\n\tstate = running\n\tpid = 535\n\tendpoints = {\n\t\tpid = 9\n\t}\n}\n";
        assert_eq!(parse_pid(print), Ok(Some(535)));
    }

    #[test]
    fn ignores_nested_pid_when_not_running() {
        let print = "system/com.example.daemon = {\n\tstate = not running\n\tendpoints = {\n\t\tpid = 9\n\t}\n}\n";
        assert_eq!(parse_pid(print), Ok(None));
    }

    #[test]
    fn rejects_invalid_pid() {
        assert_eq!(parse_pid("x = {\n\tpid = abc\n}\n"), Err("abc".to_owned()));
    }
}
