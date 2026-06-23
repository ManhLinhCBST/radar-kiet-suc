$ErrorActionPreference = "Stop"

$ROOT = "D:\body_battery"

$QUESTION_FILE =
"$ROOT\assets\data\question_library.json"

$SEED_FILE =
"$ROOT\assets\data\observation_seed.json"

$OUT_FILE =
"$ROOT\assets\data\observation_engine.json"

$q =
Get-Content `
$QUESTION_FILE `
-Raw |
ConvertFrom-Json

$s =
Get-Content `
$SEED_FILE `
-Raw |
ConvertFrom-Json

function Normalize-Curve($curve) {
    switch($curve) {
        "inverse" { return "low_is_bad" }
        "direct" { return "high_is_bad" }
        "low_is_bad" { return "low_is_bad" }
        "high_is_bad" { return "high_is_bad" }
        default { throw "Unknown risk curve: $curve" }
    }
}

function Get-ValidMin($question) {
    if ($null -ne $question.min) {
        return [double]$question.min
    }
    return 0
}

function Get-ValidMax($question) {
    if ($null -ne $question.max) {
        return [double]$question.max
    }
    return 10
}

function New-DefaultObservation($question, $curve) {

    $validMin = Get-ValidMin $question
    $validMax = Get-ValidMax $question

    if ($curve -eq "high_is_bad") {
        return [pscustomobject]@{
            question_id = $question.id
            node = $question.node

            observation_type = "continuous"
            risk_model = "piecewise"
            risk_curve = "high_is_bad"

            valid_min = $validMin
            valid_max = $validMax

            green_min = 0
            green_max = 3

            yellow_min = 4
            yellow_max = 6

            red_min = 7
            red_max = 10
        }
    }

    if ($curve -eq "low_is_bad") {
        return [pscustomobject]@{
            question_id = $question.id
            node = $question.node

            observation_type = "continuous"
            risk_model = "piecewise"
            risk_curve = "low_is_bad"

            valid_min = $validMin
            valid_max = $validMax

            green_min = 8
            green_max = 10

            yellow_min = 5
            yellow_max = 7

            red_min = 0
            red_max = 4
        }
    }

    throw "Unknown curve when creating default observation: $curve"
}

$engine = [pscustomobject]@{
    version = "3.0.0"

    generated_from = @(
        "question_library.json",
        "observation_seed.json"
    )

    risk_semantics = @{
        green = "0.00-0.39"
        yellow = "0.40-0.69"
        red = "0.70-1.00"
        score_meaning = "Risk càng cao nghĩa là rủi ro hao mòn / kiệt sức càng cao."
    }

    observations = @()
}

foreach($question in $q.questions)
{
    $seed =
    $s.observations |
    Where-Object {
        $_.question_id -eq $question.id
    }

    if($seed)
    {
        $curve = Normalize-Curve $seed.risk_curve

        $engine.observations += [pscustomobject]@{
            question_id = $question.id
            node = $question.node

            observation_type = "continuous"
            risk_model = "piecewise"
            risk_curve = $curve

            valid_min = Get-ValidMin $question
            valid_max = Get-ValidMax $question

            green_min = $seed.green_min
            green_max = $seed.green_max

            yellow_min = $seed.yellow_min
            yellow_max = $seed.yellow_max

            red_min = $seed.red_min
            red_max = $seed.red_max
        }
    }
    else
    {
        $curve = Normalize-Curve $question.risk_direction

        $engine.observations +=
        New-DefaultObservation $question $curve
    }
}

$engine |
ConvertTo-Json `
-Depth 30 |
Set-Content `
$OUT_FILE `
-Encoding UTF8

Write-Host ""
Write-Host "OBSERVATION ENGINE V3 GENERATED"
Write-Host ""

Write-Host "OBSERVATIONS:"
Write-Host $engine.observations.Count

Write-Host ""
Write-Host "RISK CURVES:"
$engine.observations |
Group-Object risk_curve |
Select Name,Count |
Format-Table
