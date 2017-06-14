function assertWarn(condition, MESSAGE)
if ~condition
    warning(MESSAGE)
end