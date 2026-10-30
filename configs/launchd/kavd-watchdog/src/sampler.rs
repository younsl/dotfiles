use sysinfo::{Pid, ProcessRefreshKind, ProcessesToUpdate, System};

#[derive(Debug, thiserror::Error)]
pub enum SamplerError {
    #[error("failed to initialize process sampler: {0}")]
    Init(sysinfo::Error),
}

pub struct Sampler {
    system: System,
}

impl Sampler {
    pub fn new() -> Result<Self, SamplerError> {
        Ok(Self {
            system: System::new().map_err(SamplerError::Init)?,
        })
    }

    pub fn cpu_usage(&mut self, pid: u32) -> Option<f32> {
        let pid = Pid::from_u32(pid);
        self.system.refresh_processes_specifics(
            ProcessesToUpdate::Some(&[pid]),
            true,
            ProcessRefreshKind::nothing().with_cpu(),
        );
        self.system.process(pid).map(sysinfo::Process::cpu_usage)
    }
}
