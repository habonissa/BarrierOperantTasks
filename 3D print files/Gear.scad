//////////////////////////////////////////////////
//SECTION 1: BASIC PARAMETERS
// Kopfspiel
spiel = 0.05;
// Hoehe des Zahnkopfes ueber dem Teilkreis
modul=1;
// Laenge der Zahnstange
laenge_stange=57.15; //this, as verified by caliper, is height of the door
// Anzahl der Radzaehne
zahnzahl_ritzel=15;
// Hoehe der Zahnstange bis zur Waelzgeraden
hoehe_stange=159.27; //width of door 
// Durchmesser der Mittelbohrung des Stirnrads
bohrung_ritzel=4.9; //widest part of stepper motor is 4.9mm
// Breite der Zaehne
breite=5;
// Eingriffswinkel, Standardwert = 20 grad gemaess DIN 867. Sollte nicht groesser als 45 grad sein.
eingriffswinkel=20;
// Schraegungswinkel zur Rotationsachse, Standardwert = 0 grad (Geradverzahnung)
schraegungswinkel=20;
// Komponenten zusammengebaut fuer Konstruktion oder auseinander zum 3D-Druck 
zusammen_gebaut=0;
// Loecher zur Material-/Gewichtsersparnis bzw. Oberflaechenvergoesserung erzeugen, wenn Geometrie erlaubt
optimiert = 1;
//////////////////////////////////////////////////

/* [Hidden] */
pi = 3.14159;
rad = 57.29578;
$fn = 96;

/*	Wandelt Radian in Grad um */
function grad(eingriffswinkel) =  eingriffswinkel*rad;

/*	Wandelt Grad in Radian um */
function radian(eingriffswinkel) = eingriffswinkel/rad;

/*	Wandelt 2D-Polarkoordinaten in kartesische um
    Format: radius, phi; phi = Winkel zur x-Achse auf xy-Ebene */
function pol_zu_kart(polvect) = [
	polvect[0]*cos(polvect[1]),  
	polvect[0]*sin(polvect[1])
];

/*	Kreisevolventen-Funktion:
    Gibt die Polarkoordinaten einer Kreisevolvente aus
    r = Radius des Grundkreises
    rho = Abrollwinkel in Grad */
function ev(r,rho) = [
	r/cos(rho),
	grad(tan(rho)-radian(rho))
];

/*  Wandelt Kugelkoordinaten in kartesische um
    Format: radius, theta, phi; theta = Winkel zu z-Achse, phi = Winkel zur x-Achse auf xy-Ebene */
function kugel_zu_kart(vect) = [
	vect[0]*sin(vect[1])*cos(vect[2]),  
	vect[0]*sin(vect[1])*sin(vect[2]),
	vect[0]*cos(vect[1])
];

/*	prueft, ob eine Zahl gerade ist
	= 1, wenn ja
	= 0, wenn die Zahl nicht gerade ist */
function istgerade(zahl) =
	(zahl == floor(zahl/2)*2) ? 1 : 0;

/*	Kopiert und dreht einen Koerper */
module kopiere(vect, zahl, abstand, winkel){
	for(i = [0:zahl-1]){
		translate(v=vect*abstand*i)
			rotate(a=i*winkel, v = [0,0,1])
				children(0);
	}
}


/*  Zahnstange
    modul = Hoehe des Zahnkopfes ueber der Waelzgeraden
    laenge = Laenge der Zahnstange
    hoehe = Hoehe der Zahnstange bis zur Waelzgeraden
    breite = Breite der Zaehne
    eingriffswinkel = Eingriffswinkel, Standardwert = 20 grad gemaess DIN 867. Sollte nicht groesser als 45 grad sein.
    schraegungswinkel = Schraegungswinkel zur Zahnstangen-Querachse; 0 grad = Geradverzahnung */

//THIS MODULE = GEAR SO REMOVE THAT TO REMOVE GEAR
module stirnrad(modul, zahnzahl, breite, bohrung, eingriffswinkel = 20, schraegungswinkel = 0, optimiert = true) {

	// Dimensions-Berechnungen	
	d = modul * zahnzahl;											// Teilkreisdurchmesser
	r = d / 2;														// Teilkreisradius
	alpha_stirn = atan(tan(eingriffswinkel)/cos(schraegungswinkel));// Schraegungswinkel im Stirnschnitt
	db = d * cos(alpha_stirn);										// Grundkreisdurchmesser
	rb = db / 2;													// Grundkreisradius
	da = (modul <1)? d + modul * 2.2 : d + modul * 2;				// Kopfkreisdurchmesser nach DIN 58400 bzw. DIN 867
	ra = da / 2;													// Kopfkreisradius
	c =  (zahnzahl <3)? 0 : modul/6;								// Kopfspiel
	df = d - 2 * (modul + c);										// Fusskreisdurchmesser
	rf = df / 2;													// Fusskreisradius
	rho_ra = acos(rb/ra);											// maximaler Abrollwinkel;
																	// Evolvente beginnt auf Grundkreis und endet an Kopfkreis
	rho_r = acos(rb/r);												// Abrollwinkel am Teilkreis;
																	// Evolvente beginnt auf Grundkreis und endet an Kopfkreis
	phi_r = grad(tan(rho_r)-radian(rho_r));							// Winkel zum Punkt der Evolvente auf Teilkreis
	gamma = rad*breite/(r*tan(90-schraegungswinkel));				// Torsionswinkel fuer Extrusion
	schritt = rho_ra/16;											// Evolvente wird in 16 Stuecke geteilt
	tau = 360/zahnzahl;												// Teilungswinkel
	
	r_loch = (2*rf - bohrung)/8;									// Radius der Loecher fuer Material-/Gewichtsersparnis
	rm = bohrung/2+2*r_loch;										// Abstand der Achsen der Loecher von der Hauptachse
	z_loch = floor(2*pi*rm/(3*r_loch));								// Anzahl der Loecher fuer Material-/Gewichtsersparnis
	
	optimiert = (optimiert && r >= breite*1.5 && d > 2*bohrung);	// ist Optimierung sinnvoll?

	// Zeichnung
	union(){
		rotate([0,0,-phi_r-90*(1-spiel)/zahnzahl]){						// Zahn auf x-Achse zentrieren;
																		// macht Ausrichtung mit anderen Raedern einfacher

			linear_extrude(height = 2*breite, twist = gamma){ //gear height
				difference(){
					union(){
						zahnbreite = (180*(1-spiel))/zahnzahl+2*phi_r;
						circle(rf);										// Fusskreis	
						for (rot = [0:tau:360]){
							rotate (rot){								// "Zahnzahl-mal" kopieren und drehen
								polygon(concat(							// Zahn
									[[0,0]],							// Zahnsegment beginnt und endet im Ursprung
									[for (rho = [0:schritt:rho_ra])		// von null Grad (Grundkreis)
																		// bis maximalen Evolventenwinkel (Kopfkreis)
										pol_zu_kart(ev(rb,rho))],		// Erste Evolventen-Flanke

									[pol_zu_kart(ev(rb,rho_ra))],		// Punkt der Evolvente auf Kopfkreis

									[for (rho = [rho_ra:-schritt:0])	// von maximalen Evolventenwinkel (Kopfkreis)
																		// bis null Grad (Grundkreis)
										pol_zu_kart([ev(rb,rho)[0], zahnbreite-ev(rb,rho)[1]])]
																		// Zweite Evolventen-Flanke
																		// (180*(1-spiel)) statt 180 Grad,
																		// um Spiel an den Flanken zu erlauben
									)
								);
							}
						}
					}			
					circle(r = rm+r_loch*1.49);							// "Bohrung"
				}
			}
		}
		// mit Materialersparnis
		if (optimiert) {
			linear_extrude(height = breite){
				difference(){ //gear height
						circle(r = (bohrung+r_loch)/2);
						circle(r = bohrung/2);							// Bohrung
					}
				}
			linear_extrude(height = (breite-r_loch/2 < breite*2/3) ? breite*2/3 : breite-r_loch/2){
				difference(){
					circle(r=rm+r_loch*1.51);
					union(){
						circle(r=(bohrung+r_loch)/2);
						for (i = [0:1:z_loch]){
							translate(kugel_zu_kart([rm,90,i*360/z_loch]))
								circle(r = r_loch);
						}
					}
				}
			}
		}
		// ohne Materialersparnis
		else {
			linear_extrude(height = breite){
				difference(){
					circle(r = rm+r_loch*1.51);
					circle(r = bohrung/2);
				}
			}
		}
	}
}

/*	Zahnstange und Ritzel
    modul = Hoehe des Zahnkopfes ueber dem Teilkreis
    laenge_stange = Laenge der Zahnstange
    zahnzahl_ritzel = Anzahl der Radzaehne am Ritzel
	hoehe_stange = Hoehe der Zahnstange bis zur Waelzgeraden
    bohrung_ritzel = Durchmesser der Mittelbohrung des Ritzels
	breite = Breite der Zaehne
    eingriffswinkel = Eingriffswinkel, Standardwert = 20 grad gemaess DIN 867. Sollte nicht groesser als 45 grad sein.
    schraegungswinkel = Schraegungswinkel, Standardwert = 0 grad (Geradverzahnung)
	optimiert = Loecher zur Material-/Gewichtsersparnis bzw. Oberflaechenvergoesserung erzeugen, wenn Geometrie erlaubt (= 1, wenn wahr) */
module zahnstange_und_rad (modul, laenge_stange, zahnzahl_ritzel, hoehe_stange, bohrung_ritzel, breite, eingriffswinkel=20, schraegungswinkel=0, zusammen_gebaut=true, optimiert=true) {

	abstand = zusammen_gebaut? modul*zahnzahl_ritzel/2 : modul*zahnzahl_ritzel;
	difference () { //door - cylinders
        //first, code for the door
	zahnstange(modul, laenge_stange, hoehe_stange, breite, eingriffswinkel, -schraegungswinkel); 

}
	translate([0,abstand,0])
		if (istgerade(zahnzahl_ritzel)) {
			rotate(90 + 180/zahnzahl_ritzel)
				stirnrad (modul, zahnzahl_ritzel, breite, bohrung_ritzel, eingriffswinkel, schraegungswinkel, optimiert);
		}
		else {
			rotate(a=90) 
				stirnrad (modul, zahnzahl_ritzel, breite, bohrung_ritzel, eingriffswinkel, schraegungswinkel, optimiert);
		}
}


    

zahnstange_und_rad (modul, laenge_stange, zahnzahl_ritzel, hoehe_stange, bohrung_ritzel, breite, eingriffswinkel, schraegungswinkel, zusammen_gebaut, optimiert);