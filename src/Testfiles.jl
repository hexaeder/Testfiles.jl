module Testfiles

using Test: Test, AbstractTestSet
using IOCapture: IOCapture

export @testfile

"""
    @testfile "path/to/test.jl"

Run a Julia test file in an isolated anonymous module.

The file is always included inside a fresh module, so there are no name-collision issues
between files and no global namespace pollution.

When called **outside** a `@testset`, the file runs normally with all output visible.

When called **inside** a `@testset`, all output is captured and suppressed unless there are
failures. A single line summary is allways printed.

This keeps the test runner output concise: a long suite prints one line per file instead
of flooding the terminal with passing-test noise.
"""
macro testfile(filename_ex)
    filename = eval(filename_ex)
    if !isfile(filename)
        error("File $filename does not exist!")
    end
    name = splitext(basename(filename))[1]
    mod = gensym("TmpModule_$name")

    resname = gensym("TestResult_$name")
    resquote = Meta.quot(resname)

    test_expr = quote
        global $(resname)
        @eval module $mod
            using Test
            res = @testset $filename begin
                include($filename)
            end
            setproperty!(Main, $resquote, res)
        end
        res = getproperty(Main, $resquote)
        setproperty!(Main, $resquote, nothing)
        res
    end
    quote
        if Test.get_testset() == Test.FallbackTestSet() # not in testset
            $test_expr
        else # in nested testset
            printname = rpad(string("Run ", $(name), ".jl..."), 30)
            printstyled(printname; color=:blue, bold=true)
            c = IOCapture.capture(; rethrow=Any, color=true) do
                $test_expr
            end
            set = c.value
            time = round(set.time_end - set.time_start, digits=2)
            if _anynonpass(set)
                printstyled(stdout, "Failed after $time s\n"; color=:red, bold=true)
                print(stdout, c.output)
                println(stdout)
            else # all good?
                printstyled(stdout, "Passed after $time s\n"; color=:green, bold=true)
            end
            set # still return set for nested results
        end
    end

end

# Compatible with Julia 1.10+ (field) and newer Julia (atomic accessed via function)
function _anynonpass(ts::AbstractTestSet)
    for r in ts.results
        r isa Test.Fail  && return true
        r isa Test.Error && return true
        r isa AbstractTestSet && _anynonpass(r) && return true
    end
    return false
end

end
