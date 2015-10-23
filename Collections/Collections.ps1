function New-SortedDictionary([type]$keyType, [type]$valueType)
{
    $base = [System.Collections.Generic.SortedDictionary``2]
    $ct = $base.MakeGenericType(($keyType, $valueType))
    New-Object $ct
}

function New-GenericDictionary([type]$keyType, [type]$valueType)
{
    $base = [System.Collections.Generic.Dictionary``2]
    $ct = $base.MakeGenericType(($keyType, $valueType))
    New-Object $ct
}

function New-GenericList([type]$type)
{
    $base = [System.Collections.Generic.List``1]
    $qt = $base.MakeGenericType(@($type))
    New-Object $qt
}