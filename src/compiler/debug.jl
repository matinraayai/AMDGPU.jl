# tools for dealing with compiler debug information

# `backtrace()` generates a pseudo-backtrace from LLVM IR instruction debug
# information. This works by looking up the debug information of the
# instruction, and inspecting the call sites of the containing function.
# If there's only one, repeat the process from that call. Finally, the debug
# information is converted to a Julia stack trace.
function backtrace(inst::LLVM.Instruction, bt = StackTraces.StackFrame[])
    name = Ref{Cstring}()
    filename = Ref{Cstring}()
    line = Ref{Cuint}()
    col = Ref{Cuint}()

    # look up the debug information from the current instruction
    depth = 0
    while LLVM.API.LLVMGetSourceLocation(LLVM.ref(inst), depth, name, filename,
                                         line, col) == 1
        frame = StackTraces.StackFrame(replace(unsafe_string(name[]), r";$"=>""),
                                       unsafe_string(filename[]), line[])
        push!(bt, frame)
        depth += 1
    end

    # move up the call chain
    f = LLVM.parent(LLVM.parent(inst))
    ## functions can be used as a *value* in eg. constant expressions, so filter those out
    callers = filter(val -> isa(user(val), LLVM.CallInst), collect(uses(f)))
    if !isempty(callers)
        # figure out the call sites of this instruction
        call_sites = unique(callers) do call
            # there could be multiple calls, originating from the same source location
            md = metadata(user(call))
            if haskey(md, LLVM.MD_dbg)
                md[LLVM.MD_dbg]
            else
                nothing
            end
        end

        if length(call_sites) > 1
            frame = StackTraces.StackFrame("multiple call sites", "unknown", 0)
            push!(bt, frame)
        elseif length(call_sites) == 1
            backtrace(user(first(call_sites)), bt)
        end
    end

    return bt
end

