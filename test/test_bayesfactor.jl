function probabilityM1(s₁::BigInt, t₁::BigFloat, n::BigInt)
    pM1 = factorial(s₁) ./ (exp(t₁) * (n + 1) ^(s₁ + 1))
    pM2 = (factorial(n) * factorial(s₁)) ./ factorial(n + s₁ + 1)
    p = pM1 ./(pM1 + pM2)
    p = Float64(p)
    return p
end

s1calc(x) = sum(x)
t1calc(x::Array{BigInt, 1}) = Float64(sum(log.(map(a -> factorial(a), x))))
t1calc(x::Array{Int64, 1}) = sum(log.(map(a -> factorial(a), x)))

function poissonsimulator(params, cst, targetdata)

    λ = params[1]
    simdata = rand(Poisson(λ), 100)
    s₁ = s1calc(simdata)
    if sum(simdata.>19) > 0
        t₁ = t1calc(map(x -> BigInt(x), simdata))
    else
        t₁ = t1calc(simdata)
    end
    euclidean(targetdata, [s₁, t₁]), 1
    #euclidean(targetdata[2], [s₁, t₁][2]), 1
end

function geometricsimulator(params, cst, targetdata)

    μ = params[1]
    simdata = rand(Geometric(μ), 100)
    s₁ = s1calc(simdata)
    if sum(simdata.>19) > 0
        t₁ = t1calc(map(x -> BigInt(x), simdata))
    else
        t₁ = t1calc(simdata)
    end
    euclidean(targetdata, [s₁, t₁]), 1
    #euclidean(targetdata[2], [s₁, t₁][2]), 1
end

function generatedata()
    λ = 0.5
    n = 100
    data = rand(Poisson(λ), n)
    s₁ = s1calc(data)
    t₁ = t1calc(data)
    pM1 = probabilityM1(BigInt(s₁), BigFloat(t₁), BigInt(n))

  return [s₁, t₁], pM1
end

################################################################
println("Test Bayes factors are calculated correctly (within 5% of true value)")
Random.seed!(1234)

cst = [[i] for i in 1:2]

ABCsetupsmc = ABCSMCModel([poissonsimulator, geometricsimulator], [1, 1], 1.0,
[Prior([Exponential(1)]), Prior([Uniform(0.0, 1.0)])];
nparticles = 500, maxiterations = 10^7)

ABCsetuprej = ABCRejectionModel([poissonsimulator, geometricsimulator], [1, 1], 1.0,
[Prior([Exponential(1)]), Prior([Uniform(0.0, 1.0)])];
nparticles = 500, maxiterations = 10^7)

td, pM1 = generatedata()

println("\t Checking ABC SMC model selection")
@time abcressmc = runabc(ABCsetupsmc, td);
@test isapprox(pM1, abcressmc.modelprob[1], rtol = 0.05)

println("\t Checking ABC rejection model selection")
@time abcresrej = runabc(ABCsetuprej, td);
@test isapprox(pM1, abcresrej.modelfreq[1], rtol = 0.05)

println("\t Check no errors arising from plotting")

plotmodelposterior(abcressmc, save = true)
@test isfile("ABCSMCmodelposteriors.pdf")
rm("ABCSMCmodelposteriors.pdf")

plotmodelposterior(abcresrej, save = true)
@test isfile("ABCRejectionmodelposteriors.pdf")
rm("ABCRejectionmodelposteriors.pdf")

plotparameterposterior(abcressmc, 1, save = true)
@test isfile("ABCSMCparameterposteriors-model1.pdf")
rm(("ABCSMCparameterposteriors-model1.pdf"))

plotparameterposterior(abcresrej, 1, save = true)
@test isfile("ABCRejectionparameterposteriors-model1.pdf")
rm("ABCRejectionparameterposteriors-model1.pdf")

writeoutput(abcressmc)
@test isfile("SMCModel-outputmodel1.txt")
@test isfile("SMCModel-outputmodel2.txt")
@test isfile("SMCModel-outputmodelprobabilities.txt")
rm("SMCModel-outputmodel1.txt")
rm("SMCModel-outputmodel2.txt")
rm("SMCModel-outputmodelprobabilities.txt")

writeoutput(abcresrej)
@test isfile("RejectionModel-outputmodel1.txt")
@test isfile("RejectionModel-outputmodel2.txt")
@test isfile("RejectionModel-outputmodelprobabilities.txt")
rm("RejectionModel-outputmodel1.txt")
rm("RejectionModel-outputmodel2.txt")
rm("RejectionModel-outputmodelprobabilities.txt")
