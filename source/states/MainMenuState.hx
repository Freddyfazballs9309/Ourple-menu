package states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;

import flixel.addons.display.FlxBackdrop;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.3'; // This is also used for Discord RPC
	public static var curSelected = 0;

	var bg:FlxSprite;
	var enterSpr:FlxSprite;
	
	var grid:FlxBackdrop;
	var letterD:FlxBackdrop;
	var letterU:FlxBackdrop;
	
	var shouldClose:Bool = false;
	
	var menuItems:Array<String> = [
		'story',
		'freeplay',
		'options',
		'credits'
	];
	
	var sillyGrp:FlxTypedGroup<FlxSprite>;
	var portGrp:FlxTypedGroup<FlxSprite>;

	override function create()
	{
		FlxG.sound.playMusic(Paths.music('freakyMenu'), 1);

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(0,0);
		bg.loadGraphic(Paths.image('menu/main/bg'));
		bg.setGraphicSize(Std.int(FlxG.width));
		bg.updateHitbox();
		add(bg);

		grid = new FlxBackdrop(Paths.image('menu/main/grid'), XY);
        grid.velocity.set(30, 30);
		grid.alpha = 0.6;
		add(grid);

		letterU = new FlxBackdrop(Paths.image('menu/main/lettabox'), X);
        letterU.velocity.set(-30, 0);
		letterU.flipY = true;
		add(letterU);

		letterD = new FlxBackdrop(Paths.image('menu/main/lettabox'), X);
        letterD.velocity.set(30, 0);
		letterD.y = FlxG.height - letterD.height;
		add(letterD);

		sillyGrp = new FlxTypedGroup<FlxSprite>();
		add(sillyGrp);

		portGrp = new FlxTypedGroup<FlxSprite>();
		add(portGrp);

		for (i in 0...menuItems.length)
		{
			var menuItem:FlxSprite = new FlxSprite(70 + (i * 325), 510);
			menuItem.loadGraphic(Paths.image('menu/main/' + menuItems[i] + 'bggrey'));
			menuItem.scale.set(1.4, 1.4);
			menuItem.y -= menuItem.height;
			menuItem.updateHitbox();
			menuItem.ID = i;
			sillyGrp.add(menuItem);

			if(i > 1)
				menuItem.x += 32;

			var portrait:FlxSprite = new FlxSprite(40 + (i * 5), 50);
			portrait.frames = Paths.getSparrowAtlas('menu/main/' + menuItems[i]);
			portrait.animation.addByPrefix('idle', 'mm_' + menuItems[i] + "i", 12);
			portrait.animation.addByPrefix('selected', 'mm_' + menuItems[i] + "c", 12);
			portrait.animation.play('idle');
			portrait.scale.set(1.4, 1.4);
			portrait.updateHitbox();
			portrait.ID = i;
			portGrp.add(portrait);
		}

		changeSelection(0);

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		addVirtualPad(LEFT_RIGHT, A_B);

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{
			if(controls.BACK){
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}
	
			if(controls.UI_LEFT_P)
				changeSelection(-1);
			else if(controls.UI_RIGHT_P)
				changeSelection(1);

			if (controls.ACCEPT)
			{
				if(menuItems[curSelected] != 'story'){
					FlxG.sound.play(Paths.sound('confirmMenu'));
					selectedSomethin = true;
				}

				switch (menuItems[curSelected])
				{
					case 'story':
						FlxG.camera.shake(0.02, 0.2);
					case 'freeplay':
						MusicBeatState.switchState(new FreeplayState());
					case 'options':
						MusicBeatState.switchState(new OptionsState());
						OptionsState.onPlayState = false;
						if (PlayState.SONG != null)
						{
							PlayState.SONG.arrowSkin = null;
							PlayState.SONG.splashSkin = null;
							PlayState.stageUI = 'normal';
						}
					case 'credits':
						MusicBeatState.switchState(new CreditsState());
				}
			}
		}

		super.update(elapsed);
	}

	function changeSelection(pene:Int){
		curSelected += pene;
	
		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;
	
		sillyGrp.forEach((silly) -> {
			if(silly.ID == curSelected)
				silly.loadGraphic(Paths.image('menu/main/' + menuItems[curSelected] + 'bg'));
			else
				silly.loadGraphic(Paths.image('menu/main/' + menuItems[silly.ID] + 'bggrey'));
		});
	
		portGrp.forEach((port) -> {
			if(port.ID == curSelected)
				port.animation.play('selected');
			else
				port.animation.play('idle');
		});
	}
}
