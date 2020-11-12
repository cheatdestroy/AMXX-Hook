#include <amxmodx>
#include <engine>

#pragma semicolon 1

#define PLUGIN	"Default Hook"
#define VERSION "1.0"
#define AUTHOR	"CheaT"

#define TASK_HOOK 107652

#define HOOK_MAX_SPEED 1700			//Max speed
#define HOOK_MIN_SPEED 150			//Min speed
#define HOOK_DEFAULT_SPEED 700.0	//Default speed

#define HOOK_COLOR_R 180			//Color red
#define HOOK_COLOR_G 180			//Color green
#define HOOK_COLOR_B 180			//Color blue
#define HOOK_BRIGHTNESS	180			//Brightness
#define HOOK_WIDTH 5				//Width

new g_iHookSprite, g_iHookOrigin[33][3];
new Float:g_fHookSpeed[33];

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_iHookSprite = precache_model("sprites/laserbeam.spr");
}

public plugin_init()
{
	register_clcmd("+hook","hookOn");
	register_clcmd("-hook","removeHook");
}

public client_putinserver(id)
{
	g_fHookSpeed[id] = HOOK_DEFAULT_SPEED;
}

public hookOn(id)
{
	if(!is_user_alive(id))
	{
		return PLUGIN_HANDLED;
	}

	get_user_origin(id, g_iHookOrigin[id], 3);

	set_task(0.1, "hookTask", id+TASK_HOOK, _, _, "ab");
	hookTask(id+TASK_HOOK);
	
	return PLUGIN_HANDLED;
}

public hookTask(taskid)
{
	new id = taskid - TASK_HOOK;

	if(!is_user_alive(id))
	{
		removeHook(id);
	}

	if(entity_get_int(id, EV_INT_button) & IN_JUMP)
	{
		if(g_fHookSpeed[id] < HOOK_MAX_SPEED)
		{
			g_fHookSpeed[id] += 20.0;
		}
	}
	else if(entity_get_int(id, EV_INT_button) & IN_DUCK)
	{
		if(g_fHookSpeed[id] > HOOK_MIN_SPEED)
		{
			g_fHookSpeed[id] -= 20.0;
		}
	}
	
	removeBeam(id);
	drawHook(id);
	
	new origin[3], Float:velocity[3];
	get_user_origin(id, origin);
	new distance = get_distance(g_iHookOrigin[id], origin);
	if(distance > 25)
	{
		velocity[0] = (g_iHookOrigin[id][0] - origin[0]) * (g_fHookSpeed[id] / distance);
		velocity[1] = (g_iHookOrigin[id][1] - origin[1]) * (g_fHookSpeed[id] / distance);
		velocity[2] = (g_iHookOrigin[id][2] - origin[2]) * (g_fHookSpeed[id] / distance);
		entity_set_vector(id, EV_VEC_velocity, velocity);
	}
	else
	{
		entity_set_vector(id,EV_VEC_velocity,Float:{0.0,0.0,0.0});
		entity_set_int(id, EV_INT_flags, entity_get_int(id, EV_INT_flags) | FL_FROZEN);
		//removeHook(id);
	}
}

public drawHook(id)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(1);						// TE_BEAMENTPOINT
	write_short(id);					// entid
	write_coord(g_iHookOrigin[id][0]);	// origin x
	write_coord(g_iHookOrigin[id][1]);	// origin y
	write_coord(g_iHookOrigin[id][2]);	// origin z
	write_short(g_iHookSprite);			// sprite index
	write_byte(0);						// start frame
	write_byte(0);						// framerate
	write_byte(1);						// life
	write_byte(HOOK_WIDTH);				// width
	write_byte(0);						// noise					
	write_byte(HOOK_COLOR_R);			// red
	write_byte(HOOK_COLOR_G);			// green
	write_byte(HOOK_COLOR_B);			// blue
	write_byte(HOOK_BRIGHTNESS);		// brightness
	write_byte(200);					// speed
	message_end();
}

public removeHook(id)
{
	if(task_exists(id+TASK_HOOK))
	{
		remove_task(id+TASK_HOOK);
	}

	removeBeam(id);
	entity_set_int(id, EV_INT_flags, entity_get_int(id, EV_INT_flags) & ~FL_FROZEN);
}

public removeBeam(id)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(99);
	write_short(id);
	message_end();
}