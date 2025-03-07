# This file is a part of Julia. License is MIT: https://julialang.org/license

using Test

@testset "Rationals" begin
    @test 1//1 == 1
    @test 2//2 == 1
    @test 1//1 == 1//1
    @test 2//2 == 1//1
    @test 2//4 == 3//6
    @test 1//2 + 1//2 == 1
    @test (-1)//3 == -(1//3)
    @test 1//2 + 3//4 == 5//4
    @test 1//3 * 3//4 == 1//4
    @test 1//2 / 3//4 == 2//3
    @test 1//0 == 1//0
    @test 5//0 == 1//0
    @test -1//0 == -1//0
    @test -7//0 == -1//0
    @test  (-1//2) // (-2//5) == 5//4

    @test_throws OverflowError -(0x01//0x0f)
    @test_throws OverflowError -(typemin(Int)//1)
    @test_throws OverflowError (typemax(Int)//3) + 1
    @test_throws OverflowError (typemax(Int)//3) * 2
    @test (typemax(Int)//1) * (1//typemax(Int)) == 1
    @test (typemax(Int)//1) / (typemax(Int)//1) == 1
    @test (1//typemax(Int)) / (1//typemax(Int)) == 1
    @test_throws OverflowError (1//2)^63
    @test inv((1+typemin(Int))//typemax(Int)) == -1
    @test_throws OverflowError inv(typemin(Int)//typemax(Int))
    @test_throws OverflowError Rational(0x1, typemin(Int32))

    @test @inferred(rationalize(Int, 3.0, 0.0)) === 3//1
    @test @inferred(rationalize(Int, 3.0, 0)) === 3//1
    @test @inferred(rationalize(Int, 33//100; tol=0.1)) === 1//3 # because tol
    @test @inferred(rationalize(Int, 3; tol=0.0)) === 3//1
    @test @inferred(rationalize(Int8, 1000//333)) === Rational{Int8}(3//1)
    @test @inferred(rationalize(Int8, 1000//3)) === Rational{Int8}(1//0)
    @test @inferred(rationalize(Int8, 1000)) === Rational{Int8}(1//0)
    @test_throws OverflowError rationalize(UInt, -2.0)
    @test_throws ArgumentError rationalize(Int, big(3.0), -1.)
    # issue 26823
    @test_throws InexactError rationalize(Int, NaN)
    # issue 32569
    @test_throws OverflowError 1 // typemin(Int)
    @test_throws ArgumentError 0 // 0
    @test -2 // typemin(Int) == -1 // (typemin(Int) >> 1)
    @test 2 // typemin(Int) == 1 // (typemin(Int) >> 1)
    # issue 32443
    @test Int8(-128)//Int8(1) == -128
    @test_throws OverflowError Int8(-128)//Int8(-1)
    @test_throws OverflowError Int8(-1)//Int8(-128)
    @test Int8(-128)//Int8(-2) == 64
    # issue 51731
    @test Rational{Int8}(-128) / Rational{Int8}(-128) === Rational{Int8}(1)
    # issue 51731
    @test Rational{Int8}(-128) / Rational{Int8}(0) === Rational{Int8}(-1, 0)
    @test Rational{Int8}(0) / Rational{Int8}(-128) === Rational{Int8}(0, 1)

    @test_throws InexactError Rational(UInt(1), typemin(Int32))
    @test iszero(Rational{Int}(UInt(0), 1))
    @test Rational{BigInt}(UInt(1), Int(-1)) == -1
    @test Rational{Int64}(UInt(1), typemin(Int32)) == Int64(1) // Int64(typemin(Int32))

    @testset "Rational{T} constructor with concrete T" begin
        test_types = [Bool, Int8, Int64, Int128, UInt8, UInt64, UInt128, BigInt]
        test_values = Any[
            Any[zero(T) for T in test_types];
            Any[one(T) for T in test_types];
            big(-1);
            collect(Iterators.flatten(
                (T(j) for T in (Int8, Int64, Int128)) for j in [-3:-1; -128:-126;]
            ));
            collect(Iterators.flatten(
                (T(j) for T in (Int8, Int64, Int128, UInt8, UInt64, UInt128)) for j in [2:3; 126:127;]
            ));
            Any[typemax(T) for T in (Int64, Int128, UInt8, UInt64, UInt128)];
            Any[typemax(T)-one(T) for T in (Int64, Int128, UInt8, UInt64, UInt128)];
            Any[typemin(T) for T in (Int64, Int128)];
            Any[typemin(T)+one(T) for T in (Int64, Int128)];
        ]
        for x in test_values, y in test_values
            local big_r = iszero(x) && iszero(y) ? nothing : big(x) // big(y)
            for T in test_types
                if iszero(x) && iszero(y)
                    @test_throws Exception Rational{T}(x, y)
                elseif Base.hastypemax(T)
                    local T_range = typemin(T):typemax(T)
                    if numerator(big_r) ∈ T_range && denominator(big_r) ∈ T_range
                        @test big_r == Rational{T}(x, y)
                        @test Rational{T} == typeof(Rational{T}(x, y))
                    else
                        @test_throws Exception Rational{T}(x, y)
                    end
                else
                    @test big_r == Rational{T}(x, y)
                    @test Rational{T} == typeof(Rational{T}(x, y))
                end
            end
        end
    end

    for a = -5:5, b = -5:5
        if a == b == 0; continue; end
        if ispow2(b)
            @test a//b == a/b
            @test convert(Rational,a/b) == a//b
        end
        @test rationalize(a/b) == a//b
        @test a//b == a//b
        if b == 0
            @test_throws DivideError round(Integer,a//b) == round(Integer,a/b)
        else
            @test round(Integer,a//b) == round(Integer,a/b)
        end
        for c = -5:5
            @test (a//b == c) == (a/b == c)
            @test (a//b != c) == (a/b != c)
            @test (a//b <= c) == (a/b <= c)
            @test (a//b <  c) == (a/b <  c)
            @test (a//b >= c) == (a/b >= c)
            @test (a//b >  c) == (a/b >  c)
            for d = -5:5
                if c == d == 0; continue; end
                @test (a//b == c//d) == (a/b == c/d)
                @test (a//b != c//d) == (a/b != c/d)
                @test (a//b <= c//d) == (a/b <= c/d)
                @test (a//b <  c//d) == (a/b <  c/d)
                @test (a//b >= c//d) == (a/b >= c/d)
                @test (a//b >  c//d) == (a/b >  c/d)
            end
        end
    end

    @test 0.5 == 1//2
    @test 0.1 != 1//10
    @test 0.1 == 3602879701896397//36028797018963968
    @test Inf == 1//0 == 2//0 == typemax(Int)//0
    @test -Inf == -1//0 == -2//0 == -typemax(Int)//0
    @test floatmin() != 1//(BigInt(2)^1022+1)
    @test floatmin() == 1//(BigInt(2)^1022)
    @test floatmin() != 1//(BigInt(2)^1022-1)
    @test floatmin()/2 != 1//(BigInt(2)^1023+1)
    @test floatmin()/2 == 1//(BigInt(2)^1023)
    @test floatmin()/2 != 1//(BigInt(2)^1023-1)
    @test nextfloat(0.0) != 1//(BigInt(2)^1074+1)
    @test nextfloat(0.0) == 1//(BigInt(2)^1074)
    @test nextfloat(0.0) != 1//(BigInt(2)^1074-1)

    @test 1/3 < 1//3
    @test !(1//3 < 1/3)
    @test -1/3 < 1//3
    @test -1/3 > -1//3
    @test 1/3 > -1//3
    @test 1/5 > 1//5
    @test 1//3 < Inf
    @test 0//1 < Inf
    @test 1//0 == Inf
    @test -1//0 == -Inf
    @test -1//0 != Inf
    @test 1//0 != -Inf
    @test !(1//0 < Inf)
    @test !(1//3 < NaN)
    @test !(1//3 == NaN)
    @test !(1//3 > NaN)

    # PR 29561
    @test abs(one(Rational{UInt})) === one(Rational{UInt})
    @test abs(one(Rational{Int})) === one(Rational{Int})
    @test abs(-one(Rational{Int})) === one(Rational{Int})

    # inf addition
    @test 1//0 + 1//0 == 1//0
    @test -1//0 - 1//0 == -1//0
    @test_throws DivideError 1//0 - 1//0
    @test_throws DivideError -1//0 + 1//0
    @test Int128(1)//0 + 1//0 isa Rational{Int128}
    @test 1//0 + Int128(1)//0 isa Rational{Int128}
end

@testset "Rational methods" begin
    rand_int = rand(Int8)

    for T in [Int8, Int16, Int32, Int128, BigInt]
        @test numerator(convert(T, rand_int)) == rand_int
        @test denominator(convert(T, rand_int)) == 1

        @test typemin(Rational{T}) == -one(T)//zero(T)
        @test typemax(Rational{T}) == one(T)//zero(T)
        @test widen(Rational{T}) == Rational{widen(T)}
    end

    @test iszero(typemin(Rational{UInt}))

    @test Rational(Float32(rand_int)) == Rational(rand_int)

    @test Rational(Rational(rand_int)) == Rational(rand_int)

    @test begin
        var = -Rational(UInt32(0))
        var == UInt32(0)
    end

    @test Rational(rand_int, 3)/Complex(3, 2) == Complex(Rational(rand_int, 13), -Rational(rand_int*2, 39))

    @test Complex(rand_int, 0) == Rational(rand_int)
    @test Rational(rand_int) == Complex(rand_int, 0)

    @test (Complex(rand_int, 4) == Rational(rand_int)) == false
    @test (Rational(rand_int) == Complex(rand_int, 4)) == false

    @test trunc(Rational(BigInt(rand_int), BigInt(3))) == Rational(trunc(BigInt, Rational(BigInt(rand_int),BigInt(3))))
    @test  ceil(Rational(BigInt(rand_int), BigInt(3))) == Rational( ceil(BigInt, Rational(BigInt(rand_int),BigInt(3))))
    @test round(Rational(BigInt(rand_int), BigInt(3))) == Rational(round(BigInt, Rational(BigInt(rand_int),BigInt(3))))


    for a = -3:3
        @test Rational(Float32(a)) == Rational(a)
        @test Rational(a)//2 == a//2
        @test a//Rational(2) == Rational(a/2)
        @test a.//[-2, -1, 1, 2] == [-a//2, -a//1, a//1, a//2]
        for b=-3:3, c=1:3
            @test b//(a+c*im) == b*a//(a^2+c^2)-(b*c//(a^2+c^2))*im
            for d=-3:3
                @test (a+b*im)//(c+d*im) == (a*c+b*d+(b*c-a*d)*im)//(c^2+d^2)
                @test Complex(Rational(a)+b*im)//Complex(Rational(c)+d*im) == Complex(a+b*im)//Complex(c+d*im)
            end
        end
    end
end

# check type of constructed rationals
int_types = Base.BitInteger64_types
for N = int_types, D = int_types
    T = promote_type(N,D)
    @test typeof(convert(N,2)//convert(D,3)) <: Rational{T}
end

# issue #7564
@test typeof(convert(Rational{Integer},1)) === Rational{Integer}

@testset "issue #15205" begin
    T = Rational
    x = Complex{T}(1//3 + 1//4*im)
    y = Complex{T}(1//2 + 1//5*im)
    xf = Complex{BigFloat}(1//3 + 1//4*im)
    yf = Complex{BigFloat}(1//2 + 1//5*im)
    yi = 4

    @test x^y ≈ xf^yf
    @test x^yi ≈ xf^yi
    @test x^true ≈ xf^true
    @test x^false == xf^false
    @test x^1 ≈ xf^1
    @test xf^Rational(2, 1) ≈ xf*xf
    @test Complex(1., 1.)^Rational(2,1) == Complex(1., 1.)*Complex(1.,1.) == Complex(0., 2.)

    for Tf = (Float16, Float32, Float64), Ti = (Int16, Int32, Int64)
        almost_half  = Rational(div(typemax(Ti),Ti(2))  , typemax(Ti))
        over_half    = Rational(div(typemax(Ti),Ti(2))+one(Ti), typemax(Ti))
        exactly_half = Rational(one(Ti)  , Ti(2))

        @test round( almost_half) == 0//1
        @test round(-almost_half) == 0//1
        @test round(Tf,  almost_half, RoundNearestTiesUp) == 0.0
        @test round(Tf, -almost_half, RoundNearestTiesUp) == 0.0
        @test round(Tf,  almost_half, RoundNearestTiesAway) == 0.0
        @test round(Tf, -almost_half, RoundNearestTiesAway) == 0.0

        @test round( exactly_half) == 0//1 # rounds to closest _even_ integer
        @test round(-exactly_half) == 0//1 # rounds to closest _even_ integer
        @test round(Tf,  exactly_half, RoundNearestTiesUp) == 1.0
        @test round(Tf, -exactly_half, RoundNearestTiesUp) == 0.0
        @test round(Tf,  exactly_half, RoundNearestTiesAway) == 1.0
        @test round(Tf, -exactly_half, RoundNearestTiesAway) == -1.0


        @test round(over_half) == 1//1
        @test round(-over_half) == -1//1
        @test round(Tf,  over_half, RoundNearestTiesUp) == 1.0
        @test round(Tf,  over_half, RoundNearestTiesAway) == 1.0
        @test round(Tf, -over_half, RoundNearestTiesUp) == -1.0
        @test round(Tf, -over_half, RoundNearestTiesAway) == -1.0

        @test round(Tf, 11//2, RoundNearestTiesUp) == 6.0
        @test round(Tf, -11//2, RoundNearestTiesUp) == -5.0
        @test round(Tf, 11//2, RoundNearestTiesAway) == 6.0
        @test round(Tf, -11//2, RoundNearestTiesAway) == -6.0

        @test round(Tf, Ti(-1)//zero(Ti)) == -Inf
        @test round(Tf, one(1)//zero(Ti)) == Inf
        @test round(Tf, Ti(-1)//zero(Ti), RoundNearestTiesUp) == -Inf
        @test round(Tf, one(1)//zero(Ti), RoundNearestTiesUp) == Inf
        @test round(Tf, Ti(-1)//zero(Ti), RoundNearestTiesAway) == -Inf
        @test round(Tf, one(1)//zero(Ti), RoundNearestTiesAway) == Inf

        @test round(Tf, zero(Ti)//one(Ti)) == 0
        @test round(Tf, zero(Ti)//one(Ti), RoundNearestTiesUp) == 0
        @test round(Tf, zero(Ti)//one(Ti), RoundNearestTiesAway) == 0
    end
end
@testset "show and Rationals" begin
    io = IOBuffer()
    rational1 = Rational(1465, 8593)
    rational2 = Rational(-4500, 9000)
    @test sprint(show, rational1) == "1465//8593"
    @test sprint(show, rational2) == "-1//2"
    @test sprint(show, -2//2) == "-1//1"
    @test sprint(show, [-2//2,]) == "Rational{$Int}[-1]"
    @test sprint(show, MIME"text/plain"(), Union{Int, Rational{Int}}[7 3//6; 6//3 2]) ==
        "2×2 Matrix{Union{Rational{$Int}, $Int}}:\n  7    1//2\n 2//1   2"
    let
        io1 = IOBuffer()
        write(io1, rational1)
        io1.ptr = 1
        @test read(io1, typeof(rational1)) == rational1

        io2 = IOBuffer()
        write(io2, rational2)
        io2.ptr = 1
        @test read(io2, typeof(rational2)) == rational2
    end
end
@testset "abs overflow for Rational" begin
    @test_throws OverflowError abs(typemin(Int) // 1)
end
@testset "parse" begin
    # Non-negative Int in which parsing is expected to work
    @test parse(Rational{Int}, string(10)) == 10 // 1
    @test parse(Rational{Int}, "100/10" ) == 10 // 1
    @test parse(Rational{Int}, "100 / 10") == 10 // 1
    @test parse(Rational{Int}, "0 / 10") == 0 // 1
    @test parse(Rational{Int}, "100//10" ) == 10 // 1
    @test parse(Rational{Int}, "100 // 10") == 10 // 1
    @test parse(Rational{Int}, "0 // 10") == 0 // 1

    # Variations of the separator that should throw errors
    @test_throws ArgumentError parse(Rational{Int}, "100\\10" )
    @test_throws ArgumentError parse(Rational{Int}, "100 \\ 10")
    @test_throws ArgumentError parse(Rational{Int}, "100\\\\10" )
    @test_throws ArgumentError parse(Rational{Int}, "100 \\\\ 10")
    @test_throws ArgumentError parse(Rational{Int}, "100/ /10" )
    @test_throws ArgumentError parse(Rational{Int}, "100 / / 10")
    @test_throws ArgumentError parse(Rational{Int}, "100// /10" )
    @test_throws ArgumentError parse(Rational{Int}, "100 // / 10")
    @test_throws ArgumentError parse(Rational{Int}, "100///10" )
    @test_throws ArgumentError parse(Rational{Int}, "100 /// 10")
    @test_throws ArgumentError parse(Rational{Int}, "100÷10" )
    @test_throws ArgumentError parse(Rational{Int}, "100 ÷ 10")
    @test_throws ArgumentError parse(Rational{Int}, "100 10" )
    @test_throws ArgumentError parse(Rational{Int}, "100   10")

    # Zero denominator, negative denominator, and double negative
    @test_throws ArgumentError parse(Rational{Int}, "0//0")
    @test parse(Rational{Int}, "1000//-100") == -10 // 1
    @test parse(Rational{Int}, "-1000//-100") == 10 // 1

    # Negative Int tests in which parsing is expected to work
    @test parse(Rational{Int}, string(-10)) == -10 // 1
    @test parse(Rational{Int}, "-100/10" ) == -10 // 1
    @test parse(Rational{Int}, "-100 / 10") == -10 // 1
    @test parse(Rational{Int}, "-100//10" ) == -10 // 1

    # Variations of the separator that should throw errors (negative version)
    @test_throws ArgumentError parse(Rational{Int}, "-100\\10" )
    @test_throws ArgumentError parse(Rational{Int}, "-100 \\ 10")
    @test_throws ArgumentError parse(Rational{Int}, "-100\\\\10" )
    @test_throws ArgumentError parse(Rational{Int}, "-100 \\\\ 10")
    @test_throws ArgumentError parse(Rational{Int}, "-100/ /10" )
    @test_throws ArgumentError parse(Rational{Int}, "-100 / / 10")
    @test_throws ArgumentError parse(Rational{Int}, "-100// /10" )
    @test_throws ArgumentError parse(Rational{Int}, "-100 // / 10")
    @test_throws ArgumentError parse(Rational{Int}, "-100///10" )
    @test_throws ArgumentError parse(Rational{Int}, "-100 /// 10")
    @test_throws ArgumentError parse(Rational{Int}, "-100÷10" )
    @test_throws ArgumentError parse(Rational{Int}, "-100 ÷ 10")
    @test_throws ArgumentError parse(Rational{Int}, "-100 10" )
    @test_throws ArgumentError parse(Rational{Int}, "-100   10")
    @test_throws ArgumentError parse(Rational{Int}, "-100 -10" )
    @test_throws ArgumentError parse(Rational{Int}, "-100   -10")
    @test_throws ArgumentError parse(Rational{Int}, "100 -10" )
    @test_throws ArgumentError parse(Rational{Int}, "100   -10")
    try  # issue 44570
       parse(Rational{BigInt}, "100 10")
       @test_broken false
    catch
       @test_broken true
    end

    # A few tests for other Integer types
    @test parse(Rational{Bool}, "true") == true // true
    @test parse(Rational{UInt8}, "0xff/0xf") == UInt8(17) // UInt8(1)
    @test parse(Rational{Int8}, "-0x7e/0xf") == Int8(-126) // Int8(15)
    @test parse(Rational{BigInt}, "$(big(typemax(Int))*16)/8") == (big(typemax(Int))*2) // big(1)
    # Mixed notations
    @test parse(Rational{UInt8}, "0x64//28") == UInt8(25) // UInt8(7)
    @test parse(Rational{UInt8}, "100//0x1c") == UInt8(25) // UInt8(7)

    # Out of the bounds tests
    # 0x100 is 256, Int test works for both Int32 and Int64
    # The error must be throw even if the canonicalized fraction fits
    # (i.e., would be less than typemax after divided by 2 in examples below,
    # both over typemax values are even).
    @test_throws OverflowError parse(Rational{UInt8}, "0x100/0x1")
    @test_throws OverflowError parse(Rational{UInt8}, "0x100/0x2")
    @test_throws OverflowError parse(Rational{Int}, "$(big(typemax(Int)) + 1)/1")
    @test_throws OverflowError parse(Rational{Int}, "$(big(typemax(Int)) + 1)/2")
end # parse

@testset "round" begin
    @test round(11//2) == round(11//2, RoundNearest) == 6//1 # rounds to closest _even_ integer
    @test round(-11//2) == round(-11//2, RoundNearest) == -6//1 # rounds to closest _even_ integer
    @test round(13//2) == round(13//2, RoundNearest) == 6//1 # rounds to closest _even_ integer
    @test round(-13//2) == round(-13//2, RoundNearest) == -6//1 # rounds to closest _even_ integer
    @test round(11//3) == round(11//3, RoundNearest) == 4//1 # rounds to closest _even_ integer
    @test round(-11//3) == round(-11//3, RoundNearest) == -4//1 # rounds to closest _even_ integer

    @test round(11//2, RoundNearestTiesAway) == 6//1
    @test round(-11//2, RoundNearestTiesAway) == -6//1
    @test round(13//2, RoundNearestTiesAway) == 7//1
    @test round(-13//2, RoundNearestTiesAway) == -7//1
    @test round(11//3, RoundNearestTiesAway) == 4//1
    @test round(-11//3, RoundNearestTiesAway) == -4//1

    @test round(11//2, RoundNearestTiesUp) == 6//1
    @test round(-11//2, RoundNearestTiesUp) == -5//1
    @test round(13//2, RoundNearestTiesUp) == 7//1
    @test round(-13//2, RoundNearestTiesUp) == -6//1
    @test round(11//3, RoundNearestTiesUp) == 4//1
    @test round(-11//3, RoundNearestTiesUp) == -4//1

    @test trunc(11//2) == round(11//2, RoundToZero) == 5//1
    @test trunc(-11//2) == round(-11//2, RoundToZero) == -5//1
    @test trunc(13//2) == round(13//2, RoundToZero) == 6//1
    @test trunc(-13//2) == round(-13//2, RoundToZero) == -6//1
    @test trunc(11//3) == round(11//3, RoundToZero) == 3//1
    @test trunc(-11//3) == round(-11//3, RoundToZero) == -3//1

    @test ceil(11//2) == round(11//2, RoundUp) == 6//1
    @test ceil(-11//2) == round(-11//2, RoundUp) == -5//1
    @test ceil(13//2) == round(13//2, RoundUp) == 7//1
    @test ceil(-13//2) == round(-13//2, RoundUp) == -6//1
    @test ceil(11//3) == round(11//3, RoundUp) == 4//1
    @test ceil(-11//3) == round(-11//3, RoundUp) == -3//1

    @test floor(11//2) == round(11//2, RoundDown) == 5//1
    @test floor(-11//2) == round(-11//2, RoundDown) == -6//1
    @test floor(13//2) == round(13//2, RoundDown) == 6//1
    @test floor(-13//2) == round(-13//2, RoundDown) == -7//1
    @test floor(11//3) == round(11//3, RoundDown) == 3//1
    @test floor(-11//3) == round(-11//3, RoundDown) == -4//1

    for T in (Float16, Float32, Float64)
        @test round(T, true//false) === convert(T, Inf)
        @test round(T, true//true) === one(T)
        @test round(T, false//true) === zero(T)
        @test trunc(T, true//false) === convert(T, Inf)
        @test trunc(T, true//true) === one(T)
        @test trunc(T, false//true) === zero(T)
        @test floor(T, true//false) === convert(T, Inf)
        @test floor(T, true//true) === one(T)
        @test floor(T, false//true) === zero(T)
        @test ceil(T, true//false) === convert(T, Inf)
        @test ceil(T, true//true) === one(T)
        @test ceil(T, false//true) === zero(T)
    end

    for T in (Int8, Int16, Int32, Int64, Bool)
        @test_throws DivideError round(T, true//false)
        @test round(T, true//true) === one(T)
        @test round(T, false//true) === zero(T)
        @test_throws DivideError trunc(T, true//false)
        @test trunc(T, true//true) === one(T)
        @test trunc(T, false//true) === zero(T)
        @test_throws DivideError floor(T, true//false)
        @test floor(T, true//true) === one(T)
        @test floor(T, false//true) === zero(T)
        @test_throws DivideError ceil(T, true//false)
        @test ceil(T, true//true) === one(T)
        @test ceil(T, false//true) === zero(T)
    end

    # issue 34657
    @test round(1//0) === round(Rational, 1//0) === 1//0
    @test trunc(1//0) === trunc(Rational, 1//0) === 1//0
    @test floor(1//0) === floor(Rational, 1//0) === 1//0
    @test ceil(1//0) === ceil(Rational, 1//0) === 1//0
    @test round(-1//0) === round(Rational, -1//0) === -1//0
    @test trunc(-1//0) === trunc(Rational, -1//0) === -1//0
    @test floor(-1//0) === floor(Rational, -1//0) === -1//0
    @test ceil(-1//0) === ceil(Rational, -1//0) === -1//0
    for r = [RoundNearest, RoundNearestTiesAway, RoundNearestTiesUp,
             RoundToZero, RoundUp, RoundDown]
        @test round(1//0, r) === 1//0
        @test round(-1//0, r) === -1//0
    end

    @test @inferred(round(1//0, digits=1)) === Inf
    @test @inferred(trunc(1//0, digits=2)) === Inf
    @test @inferred(floor(-1//0, sigdigits=1)) === -Inf
    @test @inferred(ceil(-1//0, sigdigits=2)) === -Inf
end

@testset "issue 1552" begin
    @test isa(rationalize(Int8, float(pi)), Rational{Int8})
    @test rationalize(Int8, float(pi)) == 22//7
    @test rationalize(Int64, 0.957762604052997) == 42499549//44373782
    @test rationalize(Int16, 0.929261477046077) == 11639//12525
    @test rationalize(Int16, 0.2264705884044309) == 77//340
    @test rationalize(Int16, 0.39999899264235683) == 2//5
    @test rationalize(Int16, 1.1264233500618559e-5) == 0//1
    @test rationalize(UInt16, 0.6666652791223875) == 2//3
    @test rationalize(Int8, 0.9374813124660655) == 15//16
    @test rationalize(Int8, 0.003803032342443835) == 0//1
end
# issue 3412
@test convert(Rational{Int32},0.5) === Int32(1)//Int32(2)

@testset "issue 6712" begin
    @test convert(Rational{BigInt},Float64(pi)) == Float64(pi)
    @test convert(Rational{BigInt},big(pi)) == big(pi)

    @test convert(Rational,0.0) == 0
    @test convert(Rational,-0.0) == 0
    @test convert(Rational,zero(BigFloat)) == 0
    @test convert(Rational,-zero(BigFloat)) == 0
    @test convert(Rational{BigInt},0.0) == 0
    @test convert(Rational{BigInt},-0.0) == 0
    @test convert(Rational{BigInt},zero(BigFloat)) == 0
    @test convert(Rational{BigInt},-zero(BigFloat)) == 0
    @test convert(Rational{BigInt},5e-324) == 5e-324
    @test convert(Rational{BigInt},floatmin(Float64)) == floatmin(Float64)
    @test convert(Rational{BigInt},floatmax(Float64)) == floatmax(Float64)

    @test isa(convert(Float64, big(1)//2), Float64)
end
@testset "issue 16513" begin
    @test convert(Rational{Int32}, pi) == 1068966896 // 340262731
    @test convert(Rational{Int64}, pi) == 2646693125139304345 // 842468587426513207
    @test convert(Rational{Int128}, pi) == 60728338969805745700507212595448411044 // 19330430665609526556707216376512714945
    @test_throws ArgumentError convert(Rational{BigInt}, pi)
end
@testset "issue 5935" begin
    @test rationalize(Int8,  nextfloat(0.1)) == 1//10
    @test rationalize(Int64, nextfloat(0.1)) == 300239975158034//3002399751580339
    @test rationalize(Int128,nextfloat(0.1)) == 300239975158034//3002399751580339
    @test rationalize(BigInt,nextfloat(0.1)) == 300239975158034//3002399751580339
    @test rationalize(Int8,  nextfloat(0.1),tol=0.5eps(0.1)) == 1//10
    @test rationalize(Int64, nextfloat(0.1),tol=0.5eps(0.1)) == 379250494936463//3792504949364629
    @test rationalize(Int128,nextfloat(0.1),tol=0.5eps(0.1)) == 379250494936463//3792504949364629
    @test rationalize(BigInt,nextfloat(0.1),tol=0.5eps(0.1)) == 379250494936463//3792504949364629
    @test rationalize(Int8,  nextfloat(0.1),tol=1.5eps(0.1)) == 1//10
    @test rationalize(Int64, nextfloat(0.1),tol=1.5eps(0.1)) == 1//10
    @test rationalize(Int128,nextfloat(0.1),tol=1.5eps(0.1)) == 1//10
    @test rationalize(BigInt,nextfloat(0.1),tol=1.5eps(0.1)) == 1//10
    @test rationalize(BigInt,nextfloat(parse(BigFloat,"0.1")),tol=1.5eps(big(0.1))) == 1//10
    @test rationalize(Int64, nextfloat(0.1),tol=0) == 7205759403792795//72057594037927936
    @test rationalize(Int128,nextfloat(0.1),tol=0) == 7205759403792795//72057594037927936
    @test rationalize(BigInt,nextfloat(0.1),tol=0) == 7205759403792795//72057594037927936

    @test rationalize(Int8,  prevfloat(0.1)) == 1//10
    @test rationalize(Int64, prevfloat(0.1)) == 1//10
    @test rationalize(Int128,prevfloat(0.1)) == 1//10
    @test rationalize(BigInt,prevfloat(0.1)) == 1//10
    @test rationalize(BigInt,prevfloat(parse(BigFloat,"0.1"))) == 1//10
    @test rationalize(Int64, prevfloat(0.1),tol=0) == 7205759403792793//72057594037927936
    @test rationalize(Int128,prevfloat(0.1),tol=0) == 7205759403792793//72057594037927936
    @test rationalize(BigInt,prevfloat(0.1),tol=0) == 7205759403792793//72057594037927936

    @test rationalize(BigInt,nextfloat(parse(BigFloat,"0.1")),tol=0) == 46316835694926478169428394003475163141307993866256225615783033603165251855975//463168356949264781694283940034751631413079938662562256157830336031652518559744


    @test rationalize(Int8, 200f0) == 1//0
    @test rationalize(Int8, -200f0) == -1//0

    @test [rationalize(1pi,tol=0.1^n) for n=1:10] == [
                 16//5
                 22//7
                201//64
                333//106
                355//113
                355//113
              75948//24175
             100798//32085
             103993//33102
             312689//99532 ]
    @test rationalize(pi) === rationalize(BigFloat(pi))
end

@testset "issue #12536" begin
    @test Rational{Int16}(1,2) === Rational(Int16(1),Int16(2))
    @test Rational{Int16}(500000,1000000) === Rational(Int16(1),Int16(2))
end
# issue 16311
rationalize(nextfloat(0.0)) == 0//1

@testset "rational-exponent promotion rules (issue #3155)" begin
    @test 2.0f0^(1//3) == 2.0f0^(1.0f0/3)
    @test 2^(1//3) == 2^(1/3)
end

@testset "overflow in rational comparison" begin
    @test 3//2 < typemax(Int)
    @test 3//2 <= typemax(Int)
end

# issue #15920
@test Rational(0, 1) / Complex(3, 2) == 0

# issue #16282
@test_throws MethodError 3 // 4.5im

# issue #31396
@test round(1//2, RoundNearestTiesUp) === 1//1

@testset "Unary plus on Rational (issue #30749)" begin
   @test +Rational(true) == 1//1
   @test +Rational(false) == 0//1
   @test -Rational(true) == -1//1
   @test -Rational(false) == 0//1
end

# issue #27039
@testset "gcd, lcm, gcdx for Rational" begin
    # TODO: Test gcd, lcm, gcdx for Rational{BigInt}.
    for T in (Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64, UInt64, Int128, UInt128)
        a = T(6) // T(35)
        b = T(10) // T(21)
        @test gcd(a, b) === T(2)//T(105)
        @test gcd(b, a) === T(2)//T(105)
        @test lcm(a, b) === T(30)//T(7)
        if T <: Signed
            @test gcd(-a) === a
            @test lcm(-b) === b
            @test gcdx(a, b) === (T(2)//T(105), T(-11), T(4))
            @test gcd(-a, b) === T(2)//T(105)
            @test gcd(a, -b) === T(2)//T(105)
            @test gcd(-a, -b) === T(2)//T(105)
            @test lcm(-a, b) === T(30)//T(7)
            @test lcm(a, -b) === T(30)//T(7)
            @test lcm(-a, -b) === T(30)//T(7)
            @test gcdx(-a, b) === (T(2)//T(105), T(11), T(4))
            @test gcdx(a, -b) === (T(2)//T(105), T(-11), T(-4))
            @test gcdx(-a, -b) === (T(2)//T(105), T(11), T(-4))
        end

        @test gcd(a, T(0)//T(1)) === a
        @test lcm(a, T(0)//T(1)) === T(0)//T(1)
        @test gcdx(a, T(0)//T(1)) === (a, T(1), T(0))

        @test_throws ArgumentError gcdx(T(1)//T(0), T(1)//T(2))
        @test_throws ArgumentError gcdx(T(1)//T(2), T(1)//T(0))
        @test_throws ArgumentError gcdx(T(1)//T(0), T(1)//T(1))
        @test_throws ArgumentError gcdx(T(1)//T(1), T(1)//T(0))
        @test gcdx(T(1)//T(0), T(1)//T(0)) === (T(1)//T(0), T(1), T(1))
        @test_throws ArgumentError gcdx(T(1)//T(0), T(0)//T(1))
        @test gcdx(T(0)//T(1), T(0)//T(1)) === (T(0)//T(1), T(0), T(0))

        if T <: Signed
            @test_throws ArgumentError gcdx(T(-1)//T(0), T(1)//T(2))
            @test_throws ArgumentError gcdx(T(1)//T(2), T(-1)//T(0))
            @test_throws ArgumentError gcdx(T(-1)//T(0), T(1)//T(1))
            @test_throws ArgumentError gcdx(T(1)//T(1), T(-1)//T(0))
            @test gcdx(T(-1)//T(0), T(1)//T(0)) === (T(1)//T(0), T(1), T(1))
            @test gcdx(T(1)//T(0), T(-1)//T(0)) === (T(1)//T(0), T(1), T(1))
            @test gcdx(T(-1)//T(0), T(-1)//T(0)) === (T(1)//T(0), T(1), T(1))
            @test_throws ArgumentError gcdx(T(-1)//T(0), T(0)//T(1))
            @test_throws ArgumentError gcdx(T(0)//T(1), T(-1)//T(0))
        end

        @test gcdx(T(1)//T(3), T(2)) === (T(1)//T(3), T(1), T(0))
        @test lcm(T(1)//T(3), T(1)) === T(1)//T(1)
        @test_throws ArgumentError lcm(T(3)//T(1), T(1)//T(0))
        @test_throws ArgumentError lcm(T(0)//T(1), T(1)//T(0))

        @test_throws ArgumentError lcm(T(1)//T(0), T(1)//T(2))
        @test_throws ArgumentError lcm(T(1)//T(2), T(1)//T(0))
        @test_throws ArgumentError lcm(T(1)//T(0), T(1)//T(1))
        @test_throws ArgumentError lcm(T(1)//T(1), T(1)//T(0))
        @test lcm(T(1)//T(0), T(1)//T(0)) === T(1)//T(0)
        @test_throws ArgumentError lcm(T(1)//T(0), T(0)//T(1))
        @test lcm(T(0)//T(1), T(0)//T(1)) === T(0)//T(1)

        if T <: Signed
            @test_throws ArgumentError lcm(T(-1)//T(0), T(1)//T(2))
            @test_throws ArgumentError lcm(T(1)//T(2), T(-1)//T(0))
            @test_throws ArgumentError lcm(T(-1)//T(0), T(1)//T(1))
            @test_throws ArgumentError lcm(T(1)//T(1), T(-1)//T(0))
            @test lcm(T(-1)//T(0), T(1)//T(0)) === T(1)//T(0)
            @test lcm(T(1)//T(0), T(-1)//T(0)) === T(1)//T(0)
            @test lcm(T(-1)//T(0), T(-1)//T(0)) === T(1)//T(0)
            @test_throws ArgumentError lcm(T(-1)//T(0), T(0)//T(1))
            @test_throws ArgumentError lcm(T(0)//T(1), T(-1)//T(0))
        end

        @test gcd([T(5), T(2), T(1)//T(2)]) === T(1)//T(2)
        @test gcd(T(5), T(2), T(1)//T(2)) === T(1)//T(2)

        @test lcm([T(5), T(2), T(1)//T(2)]) === T(10)//T(1)
        @test lcm(T(5), T(2), T(1)//T(2)) === T(10)//T(1)

        @test_throws ArgumentError gcd(T(1)//T(1), T(1)//T(0))
        @test_throws ArgumentError gcd(T(1)//T(0), T(0)//T(1))
    end
end

@testset "gcdx for 1 and 3+ arguments" begin
    # one-argument
    @test gcdx(7) == (7, 1)
    @test gcdx(-7) == (7, -1)
    @test gcdx(1//4) == (1//4, 1)

    # 3+ arguments
    @test gcdx(2//3) == gcdx(2//3) == (2//3, 1)
    @test gcdx(15, 12, 20) == (1, 7, -7, -1)
    @test gcdx(60//4, 60//5, 60//3) == (1//1, 7, -7, -1)
    abcd = (105, 1638, 2145, 3185)
    d, uvwp... = gcdx(abcd...)
    @test d == sum(abcd .* uvwp) # u*a + v*b + w*c + p*d == gcd(a, b, c, d)
    @test (@inferred gcdx(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)) isa NTuple{11, Int}
end

@testset "Binary operations with Integer" begin
    @test 1//2 - 1 == -1//2
    @test -1//2 + 1 == 1//2
    @test 1 - 1//2 == 1//2
    @test 1 + 1//2 == 3//2
    for q in (19//3, -4//5), i in (6, -7)
        @test rem(q, i) == q - i*div(q, i)
        @test mod(q, i) == q - i*fld(q, i)
    end
    @test 1//2 * 3 == 3//2
    @test -3 * (1//2) == -3//2
    @test (6//5) // -3 == -2//5
    @test -4 // (-6//5) == 10//3

    @test_throws OverflowError UInt(1)//2 - 1
    @test_throws OverflowError 1 - UInt(5)//2
    @test_throws OverflowError 1//typemax(Int64) + 1
    @test_throws OverflowError Int8(1) + Int8(5)//(Int8(127)-Int8(1))
    @test_throws InexactError UInt(1)//2 * -1
    @test_throws OverflowError typemax(Int64)//1 * 2
    @test_throws OverflowError -1//1 * typemin(Int64)

    @test Int8(1) + Int8(4)//(Int8(127)-Int8(1)) == Int8(65) // Int8(63)
    @test -Int32(1) // typemax(Int32) - Int32(1) == typemin(Int32) // typemax(Int32)
    @test 1 // (typemax(Int128) + BigInt(1)) - 2 == (1 + BigInt(2)*typemin(Int128)) // (BigInt(1) + typemax(Int128))
end

@testset "Promotions on binary operations with Rationals (#36277)" begin
    inttypes = (Base.BitInteger_types..., BigInt)
    for T in inttypes, S in inttypes
        U = Rational{promote_type(T, S)}
        @test typeof(one(Rational{T}) + one(S)) == typeof(one(S) + one(Rational{T})) == typeof(one(Rational{T}) + one(Rational{S})) == U
        @test typeof(one(Rational{T}) - one(S)) == typeof(one(S) - one(Rational{T})) == typeof(one(Rational{T}) - one(Rational{S})) == U
        @test typeof(one(Rational{T}) * one(S)) == typeof(one(S) * one(Rational{T})) == typeof(one(Rational{T}) * one(Rational{S})) == U
        @test typeof(one(Rational{T}) // one(S)) == typeof(one(S) // one(Rational{T})) == typeof(one(Rational{T}) // one(Rational{S})) == U
    end
    @test (-40//3) // 0x5 == 0x5 // (-15//8) == -8//3
    @test (-4//7) // (0x1//0x3) == (0x4//0x7) // (-1//3) == -12//7
    @test -3//2 + 0x1//0x1 == -3//2 + 0x1 == 0x1//0x1 + (-3//2) == 0x1 + (-3//2) == -1//2
    @test 0x3//0x5 - 2//3 == 3//5 - 0x2//0x3 == -1//15
    @test rem(-12//5, 0x2//0x1) == rem(-12//5, 0x2) == -2//5
    @test mod(0x3//0x1, -4//7) == mod(0x3, -4//7) == -3//7
    @test -1//5 * 0x3//0x2 == 0x3//0x2 * -1//5 == -3//10
    @test -2//3 * 0x1 == 0x1 * -2//3 == -2//3
end

@testset "ispow2 and iseven/isodd" begin
    @test ispow2(4//1)
    @test ispow2(1//8)
    @test !ispow2(3//8)
    @test !ispow2(0//1)
    @test iseven(4//1) && !isodd(4//1)
    @test !iseven(3//1) && isodd(3//1)
    @test !iseven(3//8) && !isodd(3//8)
end

@testset "checked_den with different integer types" begin
    @test Base.checked_den(Int8(4), Int32(8)) == Base.checked_den(Int32(4), Int32(8))
end

@testset "Rational{T} with non-concrete T (issue #41222)" begin
    @test @inferred(Rational{Integer}(2,3)) isa Rational{Integer}
    @test @inferred(Rational{Unsigned}(2,3)) isa Rational{Unsigned}
    @test @inferred(Rational{Signed}(2,3)) isa Rational{Signed}
    @test_throws InexactError Rational{Unsigned}(-1,1)
    @test_throws InexactError Rational{Unsigned}(-1)
    @test Rational{Unsigned}(Int8(-128), Int8(-128)) === Rational{Unsigned}(0x01, 0x01)
    @test Rational{Unsigned}(Int8(-128), Int8(-1)) === Rational{Unsigned}(0x80, 0x01)
    @test Rational{Unsigned}(Int8(0), Int8(-128)) === Rational{Unsigned}(0x00, 0x01)
    # Numerator and denominator should have the same type.
    @test Rational{Integer}(0x02) === Rational{Integer}(0x02, 0x01)
    @test Rational{Integer}(Int16(3)) === Rational{Integer}(Int16(3), Int16(1))
    @test Rational{Integer}(0x01,-1) === Rational{Integer}(-1, 1)
    @test Rational{Integer}(-1, 0x01) === Rational{Integer}(-1, 1)
    @test_throws InexactError Rational{Integer}(Int8(-1), UInt8(1))
end

@testset "issue #41489" begin
    @test Core.Compiler.return_type(+, NTuple{2, Rational}) == Rational
    @test Core.Compiler.return_type(-, NTuple{2, Rational}) == Rational

    A=Rational[1 1 1; 2 2 2; 3 3 3]
    @test @inferred(A*A) isa Matrix{Rational}
end

@testset "issue #42560" begin
    @test rationalize(0.5 + 0.5im) == 1//2 + 1//2*im
    @test rationalize(float(pi)im) == 0//1 + 165707065//52746197*im
    @test rationalize(Int8, float(pi)im) == 0//1 + 22//7*im
    @test rationalize(1.192 + 2.233im) == 149//125 + 2233//1000*im
    @test rationalize(Int8, 1.192 + 2.233im) == 118//99 + 67//30*im
end
@testset "rationalize(Complex) with tol" begin
    # test: rationalize(x::Complex; kvs...)
    precise_next = 7205759403792795//72057594037927936
    @assert Float64(precise_next) == nextfloat(0.1)
    @test rationalize(Int64, nextfloat(0.1) * im; tol=0) == precise_next * im
    @test rationalize(0.1im; tol=eps(0.1)) == rationalize(0.1im)
end

@testset "complex numerator, denominator" begin
    z = complex(3*3, 2*3*5)
    @test z === numerator(z) === numerator(z // 2) === numerator(z // 5)
    @test complex(3, 2*5) === numerator(z // 3)
    @test isone(denominator(z))
    @test 2 === denominator(z // 2)
    @test 1 === denominator(z // 3)
    @test 5 === denominator(z // 5)
    for den ∈ 1:10
        q = z // den
        @test q === (numerator(q)//denominator(q))
    end
    @testset "do not overflow silently" begin
        @test_throws OverflowError numerator(Int8(1)//Int8(31) + Int8(8)im//Int8(3))
    end
end
