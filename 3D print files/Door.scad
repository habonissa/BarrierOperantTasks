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
module zahnstange(modul, laenge, hoehe, breite, eingriffswinkel = 20, schraegungswinkel = 0) {

	// Dimensions-Berechnungen
	//modul=0.99;// modul*(1-spiel);
	c = modul / 6;												// Kopfspiel
	mx = modul/cos(schraegungswinkel);							// Durch Schraegungswinkel verzerrtes modul in x-Richtung
	a = 2*mx*tan(eingriffswinkel)+c*tan(eingriffswinkel);		// Flankenbreite
	b = pi*mx/2-2*mx*tan(eingriffswinkel);						// Kopfbreite
	x = breite*tan(schraegungswinkel);							// Verschiebung der Oberseite in x-Richtung durch Schraegungswinkel
	nz = ceil((laenge+abs(2*x))/(pi*mx));						// Anzahl der Zaehne
	
	translate([-pi*mx*(floor(nz/2)-1)-a-b/2,-modul,0]){
		intersection(){
			kopiere([1,0,0], nz, pi*mx, 0){
				polyhedron(
					points=[[0,-c,0], [a,2*modul,0], [a+b,2*modul,0], [2*a+b,-c,0], [pi*mx,-c,0], [pi*mx,modul-hoehe,0], [0,modul-hoehe,0],	// Unterseite
						[0+x,-c,breite], [a+x,2*modul,breite], [a+b+x,2*modul,breite], [2*a+b+x,-c,breite], [pi*mx+x,-c,breite], [pi*mx+x,modul-hoehe,breite], [0+x,modul-hoehe,breite]],	// Oberseite
					faces=[[6,5,4,3,2,1,0],						// Unterseite
						[1,8,7,0],
						[9,8,1,2],
						[10,9,2,3],
						[11,10,3,4],
						[12,11,4,5],
						[13,12,5,6],
						[7,13,6,0],
						[7,8,9,10,11,12,13],					// Oberseite
					]
				);
			};
			translate([abs(x),-hoehe+modul-0.5,-0.5]){
				cube([laenge,hoehe+modul+1,breite+1]);
			}	
		};
	};	
}

/*  Stirnrad
    modul = Hoehe des Zahnkopfes ueber dem Teilkreis
    zahnzahl = Anzahl der Radzaehne
    breite = Zahnbreite
    bohrung = Durchmesser der Mittelbohrung
    eingriffswinkel = Eingriffswinkel, Standardwert = 20 grad gemaess DIN 867. Sollte nicht groesser als 45 grad sein.
    schraegungswinkel = Schraegungswinkel zur Rotationsachse; 0 grad = Geradverzahnung
	optimiert = Loecher zur Material-/Gewichtsersparnis bzw. Oberflaechenvergoesserung erzeugen, wenn Geometrie erlaubt (= 1, wenn wahr) */

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
        union () { //allow multiple cylinders
            //then, code for the two cylinders
        { 
            
     rotate([90,90,90]) //cylinder orientation
     translate([-2.5,-3,-40]) //where hole is
     cylinder(h=81, r=2.5/2); //2mm hole, 1mm r
           
     rotate([90,90,90]) //cylinder orientation
     translate([-2.5,-152.27,-40]) //where hole is
     cylinder(h=81, r=2.5/2); //2mm hole, 1mm r
            
        }
    }
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