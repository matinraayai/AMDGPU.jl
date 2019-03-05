module AMDGPUnative

using LLVM, LLVM.Interop
using InteractiveUtils

include("cgutils.jl")
# TODO
# include("pointer.jl")

# TODO device code
# needs to be loaded _before_ the compiler infrastructure, because of generated functions
# include(joinpath("device", "array.jl"))
# include(joinpath("device", "intrinsics.jl"))
# include(joinpath("device", "libdevice.jl"))

include("jit.jl")

# TODO
# include("execution.jl")
# include("reflection.jl")
# include("irvalidation.jl")

const jlctx = Ref{LLVM.Context}()

function __init__()

    jlctx[] = LLVM.Context(convert(LLVM.API.LLVMContextRef,
                                   cglobal(:jl_LLVMContext, Nothing)))

    init_jit()
end

end # module
