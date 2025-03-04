@testitem "hip - core" begin

using Test
using LinearAlgebra
using Random

using AMDGPU: HIP, Runtime, Device, Mem
import AMDGPU: @allowscalar

Random.seed!(1)
AMDGPU.allowscalar(false)

@testset "AMDGPU.@elapsed" begin
    xgpu = AMDGPU.rand(Float32, 100)
    t = AMDGPU.@elapsed xgpu .+= 1
    @test t isa AbstractFloat
    @test t >= 0

    x = rand(Float32, 100)
    t = AMDGPU.@elapsed begin
        copyto!(xgpu, x)
        copyto!(x, xgpu)
    end
    @test t isa AbstractFloat
    @test t >= 0
end

if length(AMDGPU.devices()) > 1
    @testset "HIP Peer Access" begin
        dev1, dev2, _ = AMDGPU.devices()
        @test AMDGPU.HIP.can_access_peer(dev1, dev2) isa Bool
    end
end

if AMDGPU.functional(:rocblas)
    include("rocarray/blas.jl")
end
if AMDGPU.functional(:MIOpen)
    include("dnn/miopen.jl")
end
if AMDGPU.functional(:rocrand)
    include("rocarray/random.jl")
end

end
