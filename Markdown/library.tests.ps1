$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".tests.", ".")
. "$here\$sut"

Describe "Get-MarkdownMetaData"{
    It "can pull title and layout"{

        $testMarkdownContent = @"
---
layout: default
title: this is the title
---
#h1
"@
        $metaData = Get-MarkdownMetaData $testMarkdownContent
        $metaData.layout
        $metaData.title
    }
}

Describe "Remove-MarkdownMetaData"{
    It "removes all metadata and surrounding symbols"{
        $testMarkdownContent = @"
---
layout: default
title: this is the title
---
a
"@
        $result = Remove-MarkdownMetaData $testMarkdownContent
        $result | Should Be "a`r`n"
    }
}

Describe "Get-LayoutContentHashTable"{
    It "gets layout hashtable when given root directory"{
        $hashTable = Get-LayoutContentHashTable $PSScriptRoot
        $hashTable.Count | Should Be 1
    }

    It "gets layout hashtable when given root directory and pattern"{
        $hashTable = Get-LayoutContentHashTable $PSScriptRoot "_layout"
        $hashTable.Count | Should Be 1
    }

    It "always returns one entry when given invalid root"{
        $hashTable = Get-LayoutContentHashTable "c:\123"
        $hashTable.Count | Should Be 1
    }
}