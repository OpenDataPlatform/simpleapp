

- The blank lines in the manifest are required

- When using cluster mode, there will be to pod (The job and the driver), which are independant. 
When the job is deleted (after ttlSecondsAfterFinished), the driver remains and must be cleanup up manually