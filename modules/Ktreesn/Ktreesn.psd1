@{
    RootModule        = 'Ktreesn.psm1'
    ModuleVersion     = '0.5.0'
    GUID              = 'a3f7c8e1-9b42-4d6a-b5e0-1f3c7d8a2e94'
    Author            = 'KSN / IGS-AI Collaboration'
    CompanyName       = 'Idaho Geological Survey'
    Copyright         = '(c) 2026 KSN Labs. All rights reserved.'
    Description       = 'Advanced filesystem tree viewer with structured directory mapping, snapshot diffing, and processing state tracking. Optimized for GIS workflows and Doksn integration.'

    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Get-DirectoryMap'
        'Compare-DirectoryMap'
        'Get-DirectoryState'
        'Set-DirectoryState'
        'Show-DirectoryTree'
        'Export-DirectoryMap'
        'Get-DirectoryMapSummary'
        'Get-DoksnProcessingStatus'
    )

    AliasesToExport   = @('t', 'tmap', 'tdiff', 'tstat')

    PrivateData = @{
        PSData = @{
            Tags       = @('filesystem', 'tree', 'gis', 'shapefile', 'geodatabase', 'doksn', 'igs')
            ProjectUri = 'https://github.com/kawaisunn/ksnlabs'
        }
    }
}
