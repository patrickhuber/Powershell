# the directory of the Join-Uri.tests.ps1
$script_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script_path = Join-Path $script_dir "Join-Uri.ps1"
. $script_path

Describe "Join-Uri"{
    it "joins simple uri"{
        $result = Join-Uri -uri "https://www.google.com" -childPath "hello"
        $expected = "https://www.google.com/hello"
        $result | Should Be $expected
    }
    it "joins uri when base contains trailing slash"{
        $result = Join-Uri -uri "https://www.google.com/" -childPath "hello"
        $expected = "https://www.google.com/hello"
        $result | Should Be $expected
    }
    it "joins child path when it contains slashes"{
        $result = Join-Uri -uri "https://www.google.com" -childPath "/hello/"
        $expected = "https://www.google.com/hello/"
        $result | Should Be $expected
    }
    it "joins child path when it contains a query string"{
        $result = Join-uri -uri "https://www.google.com" -childPath "?test=data"
        # valid based on https://tools.ietf.org/html/rfc3986#section-3.3
        $expected = "https://www.google.com/?test=data"
        $result | Should Be $expected
    }
}