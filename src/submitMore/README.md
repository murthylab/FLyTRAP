# TODO
- should define an interface that classes for qsub and slurm have to implement
- submit with resource (time, mem, CPUs) requests
- dependencies (`hold_jid`)`)
- getTaskID, getJobID

# submitMore
Wrapper for the PNI specific `qsub` wrapper (`submit`). Allows submitting a queue of parallel jobs. Child jobs will wait for completion of parent jobs. Useful for `prepare`-`process`-`gather` workflows (see [demo](https://github.com/postpop/submitMore/tree/master/demo)).

## Documentation
- requires fairly new Matlab version (2013a+)
- need to test - pretty buggy right now

## Internals
Parses job id of parent job (`getJobID`) and submits child job using the `-hold_jid` argument in `qsub`.
   
