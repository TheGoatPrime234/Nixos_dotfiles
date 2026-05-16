function buildMenu(gearwheel, GlobalNotifs, GlobalDashboard, nixSwitcherProcess) {
    return [
        {
            label: "Quick Set",
            load: function() {
                gearwheel.pushLevel("Quick Set", [
                    {
                        label: "RAM-Modes",
                        preview: "",
                        children: [
                            {
                                label: "Normal",
                                preview: "",
                                action: function() {
                                    nixSwitcherProcess.command = ["bash", "-c", "notify-send normal"];
                                    nixSwitcherProcess.running = true;
                                }
                            }
                        ]
		    },
		    {
			label: "QS Menus",
			preview: "",
			children: [
			    {
				label: "Notify Center",
				preview: "",
				action: function() { 
				    GlobalNotifs.toggleCenter() 
				},
			    },
			    {
				label: "Dashboard",
				preview: "",
				action: function() {
				    GlobalDashboard.toggle()
				},
			    }
			],
		    },
                ]);
            }
        },
	{
	    label: "Rice",
	    load: function() {
		gearwheel.pushLevel("Rice", [
		    {
			label: "Themes",
			load: function() {
			    var req = new XMLHttpRequest();
			    req.open("GET", "file:///home/cato/.config/nix-switcher/links.json", false);
			    req.send(null);
			    if (req.status === 200 || req.status === 0) {
				try {
				    var json = JSON.parse(req.responseText);
				    gearwheel.fullJsonData = json;
				    var items = Object.keys(json.theme).map(name => ({
					label:   name,
					preview: "",
					action:  function() {
					    var cmd = "nix-switcher settheme " + name + " && nix-switcher apply";
					    nixSwitcherProcess.command = ["bash", "-c", cmd];
					    nixSwitcherProcess.running = true;
					}
				    }));
				    gearwheel.pushLevel("Themes", items);
				} catch (e) {
				    console.log("Fehler beim lesen der json Datei:", e);
				}
			    }
			}
		    },
		    {
			label: "Wallpaper",
			load: function() {
			    var json = gearwheel.fullJsonData;
			    if (!json) {
				var req = new XMLHttpRequest();
				req.open("GET", "file:///home/cato/.config/nix-switcher/links.json", false);
				req.send(null);
				if (req.status === 200 || req.status === 0) {
				    try {
					json = JSON.parse(req.responseText);
					gearwheel.fullJsonData = json;
				    } catch (e) {
					console.log("Fehler beim lesen der json Datei:", e);
				    }
				}
			    }
			    var cfgReq = new XMLHttpRequest();
			    cfgReq.open("GET", "file:///home/cato/.config/nix-switcher/config.json", false);
			    cfgReq.send(null);
			    var walls = [];
			    if ((cfgReq.status === 200 || cfgReq.status === 0) && json) {
				try {
				    var active = JSON.parse(cfgReq.responseText).theme;
				    walls = json.theme[active] ? json.theme[active].wallpapers : [];
				} catch (e) {
				    console.log("Fehler beim lesen der json Datei:", e);
				}
			    }
			    var items = walls.map((path, idx) => ({
				label:   "",
				preview: "file://" + path,
				action: function() {
				    var cmd = "nix-switcher setwall " + idx + " && nix-switcher apply";
				    nixSwitcherProcess.command = ["bash", "-c", cmd];
				    nixSwitcherProcess.running = true;
				}
			    }));
			    gearwheel.pushLevel("Wallpaper", items);
			}
		    },
		    {
			label: "Link",
			load: function() {
			    var req = new XMLHttpRequest();
			    req.open("GET", "file:///home/cato/.config/nix-switcher/wallpaper.json", false);
			    req.send(null);
			    var walls = [];
			    if (req.status === 200 || req.status === 0) {
				try { walls = JSON.parse(req.responseText); } 
				catch(e) { console.log("Fehler beim Lesen der wallpaper.json:", e); }
			    }
			    var items = walls.map((path, idx) => ({
				label:   "",
				preview: "file://" + path,
				children: function() {
				    var themeReq = new XMLHttpRequest();
				    themeReq.open("GET", "file:///home/cato/.config/nix-switcher/links.json", false);
				    themeReq.send(null);
				    var themes = [];
				    if (themeReq.status === 200 || themeReq.status === 0) {
					try { themes = Object.keys(JSON.parse(themeReq.responseText).theme); } 
					catch(e) { console.log("Fehler beim Lesen der links.json:", e); }
				    }
				    return themes.map(name => ({
					label:   name,
					preview: "",
					action:  function() {
					    var cmd = "nix-switcher link " + idx + " " + name;
					    nixSwitcherProcess.command = ["bash", "-c", cmd];
					    nixSwitcherProcess.running = true;
					}
				    }));
				}
			    }));
			    gearwheel.pushLevel("Link › Wallpaper", items);
			}
		    },
		    {
			label: "Kittytheme",
			load: function() {
			    var req = new XMLHttpRequest();
			    req.open("GET", "file:///home/cato/.config/nix-switcher/kittythemes.json", false);
			    req.send(null);
			    var themes = [];
			    if (req.status === 200 || req.status === 0) {
				try { 
				    themes = JSON.parse(req.responseText);
				} catch(e) { 
				    console.log("Fehler beim Lesen der kittythemes.json", e); 
				}
			    }
			    
			    var items = themes.map((themename, idx) => ({
				label: themename,
				preview: "",
				action: function() {
				    var cmd = "nix-switcher setkitty " + themename + " && nix-switcher apply";
				    nixSwitcherProcess.command = ["bash", "-c", cmd];
				    nixSwitcherProcess.running = true;
				}
			    }));
			    gearwheel.pushLevel("Kittytheme", items);
			}
		    },
		    {
			label: "Apply",
			action: function() {
			    nixSwitcherProcess.command = ["bash", "-c", "nix-switcher apply"];
			    nixSwitcherProcess.running = true;
			}
		    },
		]);
	    }
	},
        {
            label: "Rebuild",
            load: function() {
                var cmd = "kitty --class kitty-floating bash -c 'restituo; echo \"\"; read -n 1 -s -r -p \"Rebuild beendet! Drücke eine beliebige Taste...\"'";
                nixSwitcherProcess.command = ["bash", "-c", cmd];
                gearwheel.visible = false;
                nixSwitcherProcess.running = true;
            }
        },
        {
            label: "Shutdown",
            load: function() {
                gearwheel.pushLevel("Shutdown", [
                    { 
			label: "Suspend",   
			preview: "", 
			action: function() { 
			    nixSwitcherProcess.command = ["bash","-c","systemctl suspend"];       
			    nixSwitcherProcess.running = true; 
			} 
		    },
                    { 
			label: "Hibernate", 
			preview: "", 
			action: function() { 
			    nixSwitcherProcess.command = ["bash","-c","systemctl hibernate"];      
			    nixSwitcherProcess.running = true; 
			} 
		    },
                    { 
			label: "Shutdown",  
			preview: "", 
			action: function() { 
			    nixSwitcherProcess.command = ["bash","-c","systemctl poweroff"];       
			    nixSwitcherProcess.running = true; 
			} 
		    },
                    { 
			label: "Reboot",    
			preview: "", 
			action: function() { 
			    nixSwitcherProcess.command = ["bash","-c","systemctl reboot"];         
			    nixSwitcherProcess.running = true; 
			} 
		    },
                    { 
			label: "Logout",    
			preview: "", 
			action: function() { 
			    nixSwitcherProcess.command = ["bash","-c","hyprctl dispatch exit"];    
			    nixSwitcherProcess.running = true; 
			} 
		    },
                    { 
			label: "Lock",      
			preview: "", 
			action: function() { 
			    nixSwitcherProcess.command = ["bash","-c","hyprlock"];                 
			    nixSwitcherProcess.running = true; 
			} 
		    }
                ]);
            }
        }
    ];
}
