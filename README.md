# game

random game I made on Godot that has no middle or end. mostly just me messing around.

## running the game

1. download (and unzip) the repository (or do something else to download the entire folder)
2. download the Godot editor binary
3. drop the editor binary into the same folder as `project.godot`
4. run the editor binary; it will run the project

## file structure

- **res://**
- **res://music** - contains music
- **res://multilevel** - contains files for multiple levels
- **res://multilevel/assets/** - contains assets
- **res://multilevel/assets/fonts/** - contains font files and font images
- **res://multilevel/assets/fonts/**&lt;font&gt;**/** - contains font files for one font
- **res://multilevel/assets/images/** - contains images that aren't used for materials or textures; e.g. 2D sprites, UI, images displayed as 3D planes
- **res://multilevel/assets/models/** - contains models in OBJ, glTF, and `Mesh` Resource (.res) formats
- **res://multilevel/assets/textures/** - contains images that are used in models and/or materials
- **res://multilevel/materials/** - contains `Material` Resource (.res) files
- **res://multilevel/scripts/** - contains scripts
- **res://multilevel/scripts/classes/** - contains scripts that define classes
- **res://multilevel/shaders/** - contains shaders
- **res://scenes/** - contains level scenes
- **res://scenes/**&lt;levelIndex&gt;**_**&lt;levelName&gt;**/** - same as res://multilevel for this single level
- **res://scenes/**&lt;levelIndex&gt;**_**&lt;levelName&gt;**/**&lt;levelName&gt;**.tscn** - contains the level's scene file
- **res://scenes/**&lt;levelIndex&gt;**_**&lt;levelName&gt;**/**&lt;levelName&gt;**\_main.gd** - the level's main script (must inherit `LevelScene`)

