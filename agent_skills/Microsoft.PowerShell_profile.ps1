Set-Location -Path "C:\repos\Hammer-Forge-Studio"


# 1. Define the Title and the Question
$Title    = "Agent Selection"
$Message  = "What agent will we run?"

# 2. Create the Options (The '&' defines the hotkey)
$Option1 = New-Object System.Management.Automation.Host.ChoiceDescription "&Producer"
$Option2 = New-Object System.Management.Automation.Host.ChoiceDescription "&QA Engineer"
$Option3 = New-Object System.Management.Automation.Host.ChoiceDescription "&Systems Programmer"
$Option4 = New-Object System.Management.Automation.Host.ChoiceDescription "Game &Designer"
$Option5 = New-Object System.Management.Automation.Host.ChoiceDescription "&Gameplay Programmer"
$Option6 = New-Object System.Management.Automation.Host.ChoiceDescription "&Character Animator"
$Option7 = New-Object System.Management.Automation.Host.ChoiceDescription "&Environment Artist"
$Option8 = New-Object System.Management.Automation.Host.ChoiceDescription "&UI/UX Designer"
$Option9 = New-Object System.Management.Automation.Host.ChoiceDescription "&Audio Engineer"
$Option10 = New-Object System.Management.Automation.Host.ChoiceDescription "&VFX Artist"
$Option11 = New-Object System.Management.Automation.Host.ChoiceDescription "&Narrative Designer"
$Option12 = New-Object System.Management.Automation.Host.ChoiceDescription "Tec&hnical Artist"
$Option13 = New-Object System.Management.Automation.Host.ChoiceDescription "&Technical Writer"
$Option14 = New-Object System.Management.Automation.Host.ChoiceDescription "Tools/Dev&Ops Engineer"
$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Option1, $Option2, $Option3, $Option4, $Option5, $Option6, $Option7, $Option8, $Option9, $Option10, $Option11, $Option12, $Option13, $Option14)

# 3. Show the Prompt (0 is the default choice if they just hit Enter)
$Result = $Host.UI.PromptForChoice($Title, $Message, $Options, 0)

# 4. Handle the Result (Returns 0, 1, or 2 based on the array index)
switch ($Result) {
    0 { claude --model "sonnet" --dangerously-skip-permissions  "As the producer, provide me a milestone summary"}
    1 { claude --model "opus" --dangerously-skip-permissions "As the qa-engineer, work your current sprint tickets" --worktree}
    2 { claude --model "sonnet" --dangerously-skip-permissions "As the systems-programmer, work your current sprint tickets" --worktree}
    3 { claude --model "sonnet" --dangerously-skip-permissions "As the game-designer, work your current sprint tickets" --worktree}
    4 { claude --model "opus" --dangerously-skip-permissions "As the gameplay-programmer, work your current sprint tickets" --worktree}
    5 { claude --model "opus" --dangerously-skip-permissions "As the character-animator, work your current sprint tickets" --worktree}
    6 { claude --model "opus" --dangerously-skip-permissions "As the environment-artist, work your current sprint tickets" --worktree}
    7 { claude --model "sonnet" --dangerously-skip-permissions "As the ui-ux-designer, work your current sprint tickets" --worktree}
    8 { claude --model "sonnet" --dangerously-skip-permissions "As the audio-engineer, work your current sprint tickets" --worktree}
    9 { claude --model "sonnet" --dangerously-skip-permissions "As the vfx-artist, work your current sprint tickets" --worktree}
    10 { claude --model "sonnet" --dangerously-skip-permissions "As the narrative-designer, work your current sprint tickets" --worktree}
    11 { claude --model "opus" --dangerously-skip-permissions "As the technical-artist, work your current sprint tickets" --worktree}
    12 { claude --model "sonnet" --dangerously-skip-permissions "As the technical-writer, work your current sprint tickets" --worktree}
    13 { claude --model "opus" --dangerously-skip-permissions "As the tools-devops-engineer, work your current sprint tickets" --worktree}
}



