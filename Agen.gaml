/**
* Name: Agen
* Based on the internal empty template. 
* Author: Asus
* Tags: 
*/


model TugasAkhirVegi

import "Init.gaml"
import "Parameter.gaml"

species Individual {
	// Atribut umum
	int live <- 1; //Status kehidupan agen, 1 hidup, 0 mati/meninggoy 
	int age; //Umur
	int sex; //Jenis kelamin, 0 male 1 female
	int angkatan; //2018-2021 untuk agen mahasiswa
	string fakultas;
	int status_agen; //1 mahasiswa, 2 dosen, 3 tendik, 4 others
	int golongan <- 0;
	string religion;
	int durasi_kelas <- 0;  
	list<map<int,int>> jadwal_kelas;//menyatakan jadwal seseorang di hari senin-jum'at, dari jam 7-18 itu 0 (gaada) atau 1 (ada) --> menjadi major agenda place
	bool terbatas <- false; //variabel utk membatasi pergerakan ke kampus jika terjadi aturan pembatasan
		
	Building current_place; //Tempat saat ini
	Building home; //Rumah agen	
	
	//Atribut Agenda
	Building major_agenda_place;
	list<map<int, Building>> agenda_week; //jadi patokan tiap waktu orang2 lagi dimana?
	
	// Atribut Klinis
	string stat_covid <- "normal"; //Status Covid (suspect, probable, confirmed, discarded, death, recovered)
	string covid_stat <- "none"; //Untuk melihat secara pasti seseorang Covid atau bukan (none, exposed, infected)
	string severity <- "none"; //Keparahan Covid, muncul setelah fix Covid
	
	bool symptomps <- false; //Gejala awal sebelum pasti Covid (disederhanakan menjadi ada dan tidak ada)
	float death_proba <- 0.0;
	string quarantine_place <- "none";
	int infection_period <- 0; //Masa inkubasi seseorang
	int incubation_period <- 0; //Masa inkubasi menuju timbul gejala
	int quarantine_period <- 0; //Masa karantina
	int illness_period <- 0; //Masa sakit
	int death_recovered_period <- 0; //Masa menuju sehat
	int recovered_period <- 0; //variabel pembantu untuk memberitahukan jumlah pasien yang recovered dari covid setiap hari
	int confirm_period <- 0; //variabel pembantu untuk memberitahukan jumlah pasien yang terkonfirmasi positif setiap harinya
	bool must_rapid_test <- false; //Status wajib test jika kena contact trace
 	bool must_PCR_test <- false; //Status wajib test jika kena contact trace
	bool vaccination <- false; //parameter untuk menandakan seseorang tervaksinasi atau tidak
	list<Individual> temp_meet;
	
	bool contact_trace <- false;
	
	map<int, list<Individual>> meet; 
	map<int, int> cek_jumlah_meet; 
	
	bool covid_traveler <- false;
	
	rgb color <- #yellow;
	aspect circle {
		//draw circle(5) color: color border: #black;
		if (stat_covid = "suspect") {
			draw circle(3) color: #white border: #black;
		} else if (stat_covid = "probable") {
			draw circle(3) color: #orange border: #black;
		} else if (stat_covid = "confirmed") {
			draw circle(3) color: #red border: #black;
		} else if (stat_covid = "discarded") {
			draw circle(3) color: #blue border: #black;
		} else if (stat_covid = "death") {
			draw circle(3) color: #black border: #black;
		} else if (stat_covid = "recovered") {
			draw circle(3) color: #green border: #black;
		} else if (stat_covid = "normal") {
			draw circle(3) color: #yellow border: #black;
		}
		highlight self color: #yellow;
	}
	
	// 1. Action masuk kedalam bangunan
	action enter_building(Building b){ 
		if ((b.type = "TT") or (b.type = "QA") or (b.type = "PE")){ //untuk lokasi selain di dalam kampus, tidak berlaku lockdown
			if (current_place != nil){
				current_place.Individuals_inside >> self;
			}
			
			current_place.capacity <- current_place.capacity+1; //keluar dari ruangan saat ini
			current_place <- b; //masuk ke dalam ruangan baru
			current_place.Individuals_inside << self;
			location <- any_location_in(current_place);
			current_place.capacity <- current_place.capacity-1;
		} else {
			if (terbatas = true){
				//do nothing
			} else if (terbatas = false){
				if (current_place != nil) {
					current_place.Individuals_inside >> self;
				}
				current_place.capacity <- current_place.capacity+1;
				if b.capacity > 0 { //kalau bisa masuk maka gas
					current_place <- b;
					current_place.Individuals_inside << self;
					location <- any_location_in(current_place);
					current_place.capacity <- current_place.capacity-1;
					
					/* cuma untuk opsi 1
					if jadwal_kelas[current_day_of_week][current_hour] = 1{
						temp_meet <- temp_meet + current_place.Individuals_inside - self;
					}
					*/
					
				} else if b.capacity = 0{ //kalau ruangannya penuh, maka stay di rumah
					current_place <- home;
					current_place.Individuals_inside << self;
					location <- any_location_in(current_place);
					current_place.capacity <- current_place.capacity-1;
				}					
			}
		}
	}
	
	reflex cek_today when: (current_hour = 20 and live = 1){
		meet[current_day] <- temp_meet;
		temp_meet <- []; //refresh lagi jadi kosong xixi
	}
	
	// 2. Reflex Add Minor Agenda Mahasiswa
	reflex agenda_minor_mahasiswa when: ((current_day_of_week = one_of(0,1,2,3,4)) and (current_hour = 2) and (live = 1) and (status_agen = 1) and (current_day <= 6)) { 
		//cek jadwal di hari tersebut mulai jam 7-21
		//setiap jadwal yang kosong, assign minor agenda
		//utk assign minor agenda, bisa jadi pulang ke rumah juga setelah jadwal kelas pokoknya :D
		float proba_activity;
		loop Time from: 7 to: 21 {
			if agenda_week[current_day_of_week][Time] = nil{
				if (Time >= 7 or Time <= 10){
					proba_activity <- 0.15*(1-activity_reduction_factor);
				} else if (Time>10 or Time<=14){
					proba_activity <- 0.25*(1-activity_reduction_factor);
				} else if (Time>14 or Time<=18){
					proba_activity <- 0.325*(1-activity_reduction_factor);
				} else if (Time>18 or Time<=22){
					proba_activity <- 0.05*(1-activity_reduction_factor);
				}
				
				if (flip(proba_activity)) {
				//assign agenda pada individu tersebut
					int check <- 0; //variabel check utk mastikan ada jadwal di proba_activity
					if (religion = "Muslim"){
						if (Time = 12){
							float proba_pray_zuhur <- 0.5;
							if(flip(proba_pray_zuhur)){
								list<Building> Lokasi_Mushalla <- Building where (each.type = "MA");
								Building temp_places <- one_of(Lokasi_Mushalla);
								agenda_week[current_day_of_week][Time] <- temp_places;
								check <- 1;
							}
						} else if (Time = 16){
							float proba_pray_ashar <- 0.125;
							if(flip(proba_pray_ashar)){
								list<Building> Lokasi_Mushalla <- Building where (each.type = "MA");
								Building temp_places <- one_of(Lokasi_Mushalla);
								agenda_week[current_day_of_week][Time] <- temp_places;
								check <- 1;
							}
						}
					}
					if (Time = 13){
						float proba_kantin <- rnd(1.0);	//perlu nyari tau proba_kantin di kampus ITB kayak gimana untuk tendik	
						if(flip(proba_kantin)){
							list<Building> Lokasi_Kantin <- Building where (each.type = "KA");
							Building temp_places <- one_of (Lokasi_Kantin);
							agenda_week[current_day_of_week][Time] <- temp_places;
							check <- 1;			
						}
					}
					if (check = 0){ //belum ada jadwal yang di assign pada jadwal tersebut, maka lgsg pulang
						agenda_week[current_day_of_week][Time] <- self.home;	
					}		
				} else { 
				//kalau gaada activity, langsung ke rumah aja
					agenda_week[current_day_of_week][Time] <- self.home;
				}
			}
		}
	}
	
	// 3. Reflex Add Minor Agenda Dosen
	reflex assign_minor_dosen when: ((current_day_of_week = one_of(0,1,2,3,4)) and (current_hour = 2) and (live = 1) and (status_agen = 2) and (current_day <= 6)) { 
		float proba_activity;
		loop Time from: 7 to: 17 {
			if agenda_week[current_day_of_week][Time] = nil{ //kalau agenda masi kosong
				if (Time >= 7 or Time <= 10){
					proba_activity <- 0.15*(1-activity_reduction_factor);
				} else if (Time>10 or Time<=14){
					proba_activity <- 0.25*(1-activity_reduction_factor);
				} else if (Time>14 or Time<=17){
					proba_activity <- 0.325*(1-activity_reduction_factor);
				}
				
				if (flip(proba_activity)) {
				//assign agenda pada individu tersebut
					int check <- 0; //variabel check utk mastikan ada jadwal di proba_activity
					if (religion = "Muslim"){
						if (Time = 12){
							float proba_pray_zuhur <- 0.5;
							if(flip(proba_pray_zuhur)){
								list<Building> Lokasi_Mushalla <-  Building where (each.type = "MA");
								Building temp_places <- one_of(Lokasi_Mushalla);
								agenda_week[current_day_of_week][Time] <- temp_places;
								check <- 1;
							}
						} else if (Time = 16){
							float proba_pray_ashar <- 0.125;
							if(flip(proba_pray_ashar)){
								list<Building> Lokasi_Mushalla <-  Building where (each.type = "MA");
								Building temp_places <- one_of(Lokasi_Mushalla);
								agenda_week[current_day_of_week][Time] <- temp_places;
								check <- 1;
							}
						}
					}
					if (Time = 13){
						float proba_kantin <- rnd(1.0);	
						if(flip(proba_kantin)){
							list<Building> Lokasi_Kantin <-  Building where (each.type = "KA");
							Building temp_places <- one_of (Lokasi_Kantin);
							agenda_week[current_day_of_week][Time] <- temp_places;
							check <- 1;			
						}
					}
					if (check = 0){ //belum ada jadwal yang di assign pada jadwal tersebut, maka stay di kantor
						agenda_week[current_day_of_week][Time] <- self.major_agenda_place;	
					}		
				} else { 
				//kalau gaada activity antara ke rumah atau kantor mereka
					float proba_go_home <- 0.3;
					if(flip(proba_go_home)){
						agenda_week[current_day_of_week][Time] <- self.home;
					} else {
						agenda_week[current_day_of_week][Time] <- self.major_agenda_place;
					}
				}
			}
		}
	}
	
	// 4. Reflex Add Minor Agenda Tendik
	reflex assign_minor_tendik when: ((current_day_of_week = one_of(0,1,2,3,4)) and (current_hour = 2) and (live = 1) and (status_agen = 3) and (current_day <= 6)) {
		loop Time from: 8 to: 16 {
			int cek_minor <- 0;
			if (Time = 12){
				if (religion = "Muslim"){
					float proba_pray_zuhur <- 0.5;
					if(flip(proba_pray_zuhur)){
						list<Building> Lokasi_Mushalla <- Building where (each.type = "MA");
						Building temp_places <- one_of(Lokasi_Mushalla);
						agenda_week[current_day_of_week][Time] <- temp_places;
						cek_minor <- 1;
					}
				}
			} else if (Time = 13){
				float proba_kantin <- rnd(1.0);
				if(flip(proba_kantin)){
					list<Building> Lokasi_Kantin <- Building where (each.type = "KA");
					Building temp_places <- one_of (Lokasi_Kantin);
					agenda_week[current_day_of_week][Time] <- temp_places;
					cek_minor <- 1;
				}
			} else if (Time = 16){
				if (religion = "Muslim"){
					float proba_pray_ashar <- 0.125;
					if(flip(proba_pray_ashar)){
						list<Building> Lokasi_Mushalla <- Building where (each.type = "MA");
						Building temp_places <- one_of(Lokasi_Mushalla);
						agenda_week[current_day_of_week][Time] <- temp_places;
						cek_minor <- 1;
					}
				}
			}
			if (cek_minor = 0){ //kalau belum ada yang di assign stay di kantor
				agenda_week[current_day_of_week][Time] <- major_agenda_place;
			}
		}
	}
	
	//5. Reflex Kematian
	reflex death when:((current_hour = 21) and (live = 1)){
		Building c <- one_of(Building where (each.type = "PE"));
		if (flip(death_proba)){
			if(stat_covid in ["normal","discarded","recovered"]){ //harusnya gabisa terjadi, karna death_proba nya 0.0
				live <- 0; //meninggal karna kondisi non covid
				do enter_building(c);
			}
			if (stat_covid in ["confirmed"]){
				live <- 0; //meninggal karna covid
				stat_covid <- "death"; 
				do enter_building(c);
			}
			else{
				live <- 0; //meninggal dalam kondisi probable ataupun suspect
				stat_covid <- "probable"; //dianggap probable
				do enter_building(c);
			}
			quarantine_period <- 0;
			quarantine_place <- "none";
			terbatas <- false;
		} else{
			live <- 1;
		} 
	}

	//6. Reflex Eksekusi Agenda
	reflex execute_agenda when: ((live = 1) and (quarantine_place = "none")) { 
	//Agenda dijalankan saat tidak karantina dan agen masih hidup
		map<int, Building> agenda_day <- agenda_week[current_day_of_week];
		if (agenda_day[current_hour] != nil) {
			do enter_building(agenda_day[current_hour]);			
		}
	}
	
	
	//Action Individual Klinis
	//1. Contact Tracing
	reflex contact_trace when: (contact_trace = true){
		list<Individual> contacts;
		//saat seseorang terkonfirmasi covid, lakukan contact tracing
		//Dimulai dengan menambahkan semua orang yang ditemui pada hari tersebut
		//pasti dilakukan jam 5 pagi (setelah hasil rapid/pcr ditemukan)
		if current_day = 0{
			contacts <- meet[current_day]; //ada orang2 yang ditemui lebih dari 1x				
		} else if current_day = 1 {
			contacts <- meet[current_day] + meet[current_day-1];
		} else if current_day > 1{
			contacts <- meet[current_day] + meet[current_day-1] + meet[current_day-2];
		}
		
		//make sure setiap individu hanya ada satu kali
		list<Individual> temp_contacts <- [];
		ask contacts{
			bool check <- false;
			ask temp_contacts{
				if self = myself{ //kalau sama, check jadi true
					check <- true;
				}
			}
			if (check = false){
				temp_contacts <- temp_contacts + self;
			}
		}
		contacts <- temp_contacts;
		
		//menentukan semua orang yang ditemui yang gagal di trace berdasarkan contact_tracing_effectiveness
		int num_contacts_untraced <- round((1-contact_tracing_effectiveness)*length(contacts));
		loop times: num_contacts_untraced {
			contacts >> one_of(contacts);
		}
		
		//Status diubah menjadi karantina dan jika patuh, maka akan di karantina ke tempat karantina
		if (contacts != []){
			ask contacts where (each.covid_stat = "none"){ 
				//kalau seseorang sudah vaksinasi, tidak perlu contact tracing. Tapi jika belum ,wajib contact tracing.
				//contact tracing cukup ke orang2 yang covid stat masih none 
				if (vaccination = false){
					if (quarantine_place = "none"){
						if (flip(obedience*quarantine_obedience)){
							quarantine_place <- "QA"; //tempat karantina kalau patuh alias ga bakal ke kampus :D 
						} else {
							quarantine_place <- "none"; //kalo ga patuh, ga karantina
						}
					}
					must_rapid_test <- flip(proba_test*obedience);	
					stat_covid <- "suspect";
					covid_stat <- "exposed";
					covid_traveler <- false;
				} else { //berarti tetep bisa positif pake efikasi
					if(flip(1-vaccination_efficacy)) {
						covid_stat <- "exposed";
						covid_traveler <- false;
						//stat_covid <- "suspect"; //mereka ga sadar karna dengan vaksin asumsi pasti bebas covid (jd ga di trace)
						//must_rapid_test <- flip(proba_test*obedience);
					}
				}
			}
		}	
		contact_trace <- false; //utk memastikan next day ga di-contact tracing lagi (kalau ga diminta)
	}
	
	//2. New Inisiasi Parameter Terinfeksi
	action init_infection {
		
		//cek symptomps seseorang
		list<int> l <- match_age(asymptomic_distribution.keys);
		float proba_asymptomic <- asymptomic_distribution[l];
		bool is_asymptomic <- flip(proba_asymptomic);
		
		if (is_asymptomic){
			symptomps <- false;
		} else {
			symptomps <- true;
		}
				
		//Menentukan waktu penyakit berubah menjadi severity
		illness_period <- int(24*(rnd(3.0,5.0))) + incubation_period; //int(24*get_proba(days_diagnose[l], "gauss")) //
		
		//Menentukan waktu penyakit berubah menjadi sembuh (lama seseorang terinfeksi covid)
		//file:///C:/Users/vegif/Downloads/ciaa1249.pdf
		if symptomps = false{
			death_recovered_period <- 24*rnd(5,7) + illness_period; //rata2 death recovered period untuk mild-moderately ill patients adalah 10 hari dari terinfeksi, maka rentangnya menjadi 5-7
		} else if symptomps = true{
			death_recovered_period <- 24*rnd(10,12) + illness_period; //rata2 death recovered period untuk severely-critically ill patients adalah 15 hari dari terinfeksi
		}
		//death_recovered_period <- int(24*13.5) + illness_period; //https://eurjmedres.biomedcentral.com/articles/10.1186/s40001-021-00513-x#Tab1
	}
	
	//Reflex Individual Klinis	
	//1. New Infeksi
	reflex infection when: (current_hour = 22 and live = 1){ 
		//setiap harinya ada kemungkinan seseorang terinfeksi covid secara tak sadar
		int num_people <- length(meet[current_day]); //bisa jadi seseorang ga ketemu siapa-siapa hari itu 
		cek_jumlah_meet[current_day] <- num_people;
		if (cek_jumlah_meet[current_day] > 0){ //ada kemungkinan tidak bertemu siapa-siapa
			list<Individual> agen_terinfeksi <- meet[current_day] where (each.covid_stat = "infected");
			int num_infected <- length(agen_terinfeksi);
			float mask_factor <- 1 - mask_effectiveness*mask_usage_proportion*obedience;
			float proba <- 0.0;
			
			if (covid_stat = "none"){
				float infection_proportion <- num_infected/num_people;
				list<int> l <- match_age(susceptibility.keys);
				proba <- get_proba(susceptibility[l],"gauss");
				proba <- proba * infection_proportion * mask_factor * (1-infection_reduction_factor);
				
				
				if (flip(proba)){ 
			 		if (vaccination = true){ //cek apakah seseorang sudah tervaksin atau belum, jika sudah bisa jadi tetap kebal dengan vaksin
			 			if(flip(1-vaccination_efficacy)){ //chance terkena covid adalah 1-efikasi vaksin, misal efikasi 95% maka 5% chance-nya
				 			covid_stat <- "exposed";
				 			infection_period <- 0;
				 			covid_traveler <- false;
				 		} //kalau ga kena, maka gausah ngapa2in hehe
			 		} else if (vaccination = false){
			 			covid_stat <- "exposed";
		 				infection_period <- 0;
		 				covid_traveler <- false;
			 		}
			 	} else {
			 		covid_stat <- "none"; //kalau else, maka tetep none
			 	}
			 	
			 	//seseorang yang awalnya tidak terinfeksi jadi terinfeksi, ada kemungkinan besoknya sukarela test rapid (karena merasa dirinya bergejala)
			 	if (covid_stat = "exposed"){ 
			 		if flip(proba_test){
			 			must_rapid_test <- true;
			 		}
			 	}
			}	
		}
		 
		//Infection yang disebabkan oleh traveler/bepergian (diluar dari kampus) atau infeksi dari luar kampus
		//cek jadwal harian yang kosong ada di jam berapa, kekosongan jadwal menambah probabilitas seseorang beraktivitas di luar kampus
		//semakin banyak jadwal kosong, maka semakin besar kemungkinan beraktivitas di luar kampus 
		//perbedaan status agen juga berpengaruh pada aktivitas diluar kegiatan kampus
		float proba_traveler <- 0.0;
		map<int, Building> agenda_day <- agenda_week[current_day_of_week];
		
		if (covid_stat = "none"){ // perlu ada perhitungan aturan pembatasan atau ga?
			loop Time from: 6 to: 19 { //hitung probability bepergian berdasarkan kekosongan agenda yang dimiliki
				float check <- 0.0;
				if (agenda_day[Time] = nil) or (agenda_day[Time] = home){
					if (status_agen = 1){
						check <- 0.125;
					} else if (status_agen in [3,4]){
						check <- 0.125/2;	
					} else if (status_agen = 2){
						check <- 0.125/4;
					}
					
					if current_day_of_week in [0,1,2,3,4]{ //kemungkinan beraktivitas di weekdays lebih kecil dibanding weekend
						check <- check/2;
					}
					
					if flip(check){ 
						proba_traveler <- proba_traveler + 0.01;
					}			
				}
			}
			
			if (status_agen = 4) and (major_agenda_place.type = "KA"){
				if (current_day_of_week in [0,1,2,3,4]) { //kalau weekdays, penjaga kantin stay di kantin aja
					if flip(0.125){
						proba_traveler <- 0.01;	
					} else {
						proba_traveler <- 0.0;
					}
				}
			}
			
			if (proba_traveler > 0.0){ //karna kalau 0 berarti tidak ada aktivitas diluar kampus pada hari tersebut
				float proba <- 0.0;
				float mask_factor <- 1 - mask_effectiveness*mask_usage_proportion;
				list<int> l <- match_age(susceptibility.keys);
				proba <- get_proba(susceptibility[l],"gauss");
				proba <- proba * mask_factor * proba_traveler;
				
				if (flip(proba)){ 
				 	if (vaccination = true){ 
				 		if(flip(1-vaccination_efficacy)){ 
					 		covid_stat <- "exposed";
					 		infection_period <- 0;
					 		covid_traveler <- true;
					 	} //kalau ga kena, maka tetep none
				 	} else if (vaccination = false){
				 		covid_stat <- "exposed";
			 			infection_period <- 0;
			 			covid_traveler <- true;
			 		}
			 	} else {
			 		covid_stat <- "none"; //kalau else, maka tetep none
			 	}
			 	
			 	if (covid_stat = "exposed"){ 
				 	if flip(proba_test){
				 		must_rapid_test <- true;
					}
				 }				
			}
		}
	}
	
	//2. New Update Status Infeksi
	reflex update_infection when: ((covid_stat in ["exposed","infected"]) and (live = 1)){
		if (infection_period = 0){ //tentukan periode inkubasi atau kapan gejala timbul
			//list<int> l <- match_age(incubation_distribution.keys); //nilai bisa 2-5 hari		
			incubation_period <- int(24*(rnd(2.0,7.0))); //https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7266766/pdf/main.pdf
			infection_period <- infection_period+1;
		} else {
			if (infection_period = incubation_period-24){ //kalau h-1 periode inkubasi (covid menuju positif)
				covid_stat <- "infected";
				infection_period <- infection_period+1;
			} else if (infection_period = incubation_period){
				do init_infection; //cek symptomps dan variabel lainnya
				
				if (symptomps = true){
					must_PCR_test <- true;
				} else {
					must_rapid_test <- true;
				}
				infection_period <- infection_period+1;
			} else if (infection_period = illness_period){
				//Merubah Gejala menjadi keparahan, meningkat. Terjadi saat waktu terinfeksi sudah berjalan (= periode infeksi)
		 		//Tingkat keparahan memengaruhi kemungkinan seseorang meninggal karna covid
				if (symptomps = false){
		 			if (flip(0.5)) {
		 				severity <- "asymptom";
	 				} else if (flip(0.4)) {
	 					severity <- "mild";
	 				} else {
	 					severity <- "moderate";
	 				}
		 		} else if (symptomps = true){
		 			if flip(0.3){
		 				severity <- "moderate";
		 			} else if (flip(0.4)){
		 				severity <- "severe";
		 			} else {
		 				severity <- "deadly";
		 			}
		 		}
		 		do proba_death_calculation;
		 		infection_period <- infection_period+1;
		 		
			} else if (infection_period = death_recovered_period){// and (death_recovered_period > 0){ //cek yang > 0
				//Kalau menuju sehat
				//Merubah atribut klinis menjadi inisasi awal
		 		covid_stat <- "none";
		 		infection_period <- 0;
		 		death_proba <- 0.0;
		 		symptomps <- false;
		 		
		 		if (quarantine_place = "none") and (covid_stat = "none") and (stat_covid = "suspect"){
		 			stat_covid <- "discarded";
		 		}
		 		
		 		//bagian dibawah ini, di-state saat seseorang sudah tidak karantina lagi (jadi ada kemungkinan seseorang sudah sembuh tapi masih karantina, cuma tidak berlaku sebaliknya)
		 		//severity <- "none";
		 		//stat_covid <- "recovered";
		 		//quarantine_place <- "none";
		 		//quarantine_period <- 0;
		 		//recovered_period <- 0;
			} else {
				infection_period <- infection_period+1;
			}
		}
	}
		
	//3. Reflex Update Quarantine
	reflex update_quarantine when: ((quarantine_place in ["home","QA"]) and (live = 1) and (current_hour = 5)){ 
		if (stat_covid in ["suspect","probable"]){
			if (quarantine_period = 13){ 
				quarantine_place <- "none";
				quarantine_period <- 0;
				stat_covid <- "discarded";
				severity <- "none";
			} else {
				quarantine_period <- quarantine_period + 1;
			} 
		} else if (stat_covid in "confirmed") { 
			if (severity = "asymptom"){
				if (quarantine_period >= 9){ 
					stat_covid <- "recovered";
					recovered_period <- 0; 
					quarantine_period <- 0; 
					quarantine_place <- "none"; 
					severity <- "none"; 
				} else {
					quarantine_period <- quarantine_period + 1;
				}
			} else if (severity in ["mild","moderate"]){ 
				if (quarantine_period >= 12) {
					stat_covid <- "recovered";
					recovered_period <- 0; 
					quarantine_period <- 0;
					quarantine_place <- "none";
					severity <- "none";
				} else {
					quarantine_period <- quarantine_period + 1;
				}
			} else if (severity in ["severe","deadly"]){ 
				if (quarantine_period >= 12){
					stat_covid <- "recovered";
					recovered_period <- 0; 
					quarantine_period <- 0;
					quarantine_place <- "none";
					severity <- "none";
				} else {
					quarantine_period <- quarantine_period + 1;
				}
			}
		} else {
			quarantine_period <- quarantine_period + 1;
		}			
	}
	
	//5. Proba Death Calculation
	action proba_death_calculation{
		bool quarantine <- flip(obedience*quarantine_obedience); //pindah karantina tempat berdasarkan keparahannya
		switch severity {
			match "asymptomic" {
				if(quarantine){
					quarantine_place <- "home"; //tetap di rumah
				}
				death_proba <- 0.033;
			} match "mild" {
				if(quarantine){
					do enter_building(one_of(buildings_per_activity["QA"]));
					quarantine_place <- "QA";
				}
				death_proba <- 0.045;
			} match "moderate" {
				if(quarantine){
					do enter_building(one_of(buildings_per_activity["QA"]));
					quarantine_place <- "QA";
				}
				death_proba <- 0.080;
			} match "severe" {
				if(quarantine){
					do enter_building(one_of(buildings_per_activity["QA"]));
					quarantine_place <- "QA";
				}
				death_proba <- 0.134;
			} match "deadly" {
				if(quarantine){
					do enter_building(one_of(buildings_per_activity["QA"]));
		 			quarantine_place <- "QA";
		 		}
		 		death_proba <- 0.4;
			}
		}
	}
	
	// 6. Reflex Update Recovered & Reflex Update Confirmed (Untuk perhitungan kondisi covid)
	reflex update_recovered when: (stat_covid = "recovered") and (live = 1){
		if (recovered_period <= 24) {
			recovered_period <- recovered_period + 1;
		} else {
			recovered_period <- 25;
		}
	}
	
	reflex update_confirmed when: (stat_covid = "confirmed") and (confirm_period <= 24){
		if (confirm_period <= 24) {
			confirm_period <- confirm_period + 1;
		} else {
			confirm_period <- 25;
		}
	}
	
	//7. Reflex Test Rapid
	//pemodelan difokuskan pada kampus, jadi kalau rapid bakal stay di rumah aja
	reflex rapid_test when: ((current_hour = 2) and (must_rapid_test = true) and (live = 1)){
		if (covid_stat in ["infected"]) {
			bool test_result <- flip(sensitivity_rapid*test_accuracy);
			if (test_result = true){ //True Positive
				stat_covid <- "confirmed";
				confirm_period <- 0;
				contact_trace <- true;
				if (symptomps = false){
					quarantine_place <- "home";
				} else if (symptomps = true){
					quarantine_place <- "QA";
				}
				quarantine_period <- 0;
			
			} else if (not(test_result)){ //Sebenarnya positif, tapi hasil negatif
				if (symptomps = false){
					stat_covid <- "suspect";
					bool quarantine <- flip(obedience*quarantine_obedience);
					if (quarantine) {
						quarantine_place <- "home";
						quarantine_period <- 0;
					} else if (not(quarantine)){
						quarantine_place <- "none";
					}
				} else if (symptomps = true) {
					stat_covid <- "probable";
					must_PCR_test <- true;
					quarantine_place <- "home";
					quarantine_period <- 0;
				}
			}
			 			
		} else if (covid_stat in ["none","exposed"]){
			bool test_results <- flip(specificity_rapid*test_accuracy);
			//spesifisitas adalah kemampuan test utk menyatakan negatif orang-orang yang tidak sakit
			//kalau bool true, maka berarti orang tersebut tidak sakit
			if (test_results) {
				if (symptomps = false){
					stat_covid <- "suspect";
					bool quarantine <- flip(obedience*quarantine_obedience);
					if (quarantine) {
						quarantine_place <- "home";
						quarantine_period <- 0;
					} else if (not(quarantine)){
						quarantine_place <- "none";
					}
				} else {
					stat_covid <- "probable";
					quarantine_place <- "home";
					must_PCR_test <- true;
					quarantine_period <- 0;
				}
				
			} else if (not(test_results)) { //sebenarnya negatif, tapi terbaca positif
				stat_covid <- "confirmed";
				confirm_period <- 0;
				contact_trace <- true;
				if (symptomps = false){
					quarantine_place <- "home";
				} else if (symptomps = true){
					quarantine_place <- "QA";
				}
				quarantine_period <- 0;
			}
		}
		must_rapid_test <- false;
		
		//pindah ke tempat karantina kalau hasil akhir test nya harus ke tempat karantina
		if quarantine_place = "QA"{
			Building h <- one_of(buildings_per_activity["QA"]);
			do enter_building(h);
		}
	}
	
	//8. Reflex Test PCR
	//pemodelan difokuskan pada kampus, jadi kalau pcr bakal stay di rumah aja
	//Hasil PCR asumsi langsung diperoleh di hari yang sama (canggihnya teknologi :D)
	//Belum memperhatikan pcr waiting day
	reflex pcr_test when: ((current_hour = 3) and ((must_PCR_test = true) and (flip(proba_test) = true)) and (live = 1)) {
		bool pcr_test_lagi <- false;
		if (covid_stat in ["infected"]) {
			bool test_result <- flip(sensitivity_pcr*test_accuracy); 
			if (test_result) { //True Positive
				stat_covid <- "confirmed";
				confirm_period <- 0;
				contact_trace <- true;
				quarantine_period <- 0;
				if symptomps = false {
					quarantine_place <- "home";
				} else if symptomps = true {
					quarantine_place <- "QA";
				}
			} else if (not(test_result)){ //harusnya positif, tapi test negatif
				if (symptomps = false){
					stat_covid <- "suspect";
				} else if (symptomps = true){
					stat_covid <- "probable";
					pcr_test_lagi <- true; //test PCR lagi di hari besoknya
					quarantine_place <- "home";
					quarantine_period <- 0;
				}
			}
			
		} else if (covid_stat in ["none","exposed"]) {
			bool test_result <- flip(specificity_pcr*test_accuracy);
			//spesifisitas adalah kemampuan test utk menyatakan negatif orang-orang yang tidak sakit
			//kalau bool true, maka berarti orang tersebut tidak sakit
			if (test_result) { //hasil test adalah dikonfirmasi negatif
				if (symptomps = false) {
					stat_covid <- "suspect";
				} else if (symptomps = true){
					stat_covid <- "probable";
					pcr_test_lagi <- true; //wajib rapid lagi besoknya untuk ngecek ulang (diganti dari rapid ke pcr_
					quarantine_place <- "home";
					quarantine_period <- 0;
				}
			} else if (not(test_result)) { //hasil test adalah dikonfirmasi tidak negatif
				stat_covid <- "confirmed";
				confirm_period <- 0;
				contact_trace <- true;
				if symptomps = false {
					quarantine_place <- "home";
				} else if symptomps = true {
					quarantine_place <- "QA";
				}
				quarantine_period <- 0;
			}
		}
		
		if (pcr_test_lagi = false){ //bisa jadi seseorang harus test PCR lagi broks
			must_PCR_test <- false;
		} else {
			must_PCR_test <- true;
		}
		
		//pindah ke tempat karantina kalau hasil akhir test nya harus ke tempat karantina
		if quarantine_place = "QA"{
			Building h <- one_of(buildings_per_activity["QA"]);
			do enter_building(h);
		}
	}
	
	//Fungsi Lainnya	
	list<int> match_age (list<list<int>> the_list) {
		/*
		 * Fungsi untuk mencocokkan atribut usia Individu dengan list<list<int>>.
		 */
		loop l over: the_list {
			if (age >= min(l) and age <= max(l)) {
				return l;
			}
		}
	}
	
	float get_proba(list<float> proba, string method) {
		/*
		 * Fungsi untuk memudahkan memanggil fungsi built-in
		 * untuk menentukan probabilitas dari distribusi.
		 */
		
		switch method {
			match "lognormal" {
				return lognormal_rnd(proba[0],proba[1]);
			}
			match "gauss" {
				return gauss_rnd(proba[0],proba[1]);
			}
			match "gamma" {
				return gamma_rnd(proba[0],proba[1]);
			}
		}
	}
	
}


species Building {
	int capacity;
	int ch <- 0 update: current_hour;
	int first_capacity; //untuk ngitung kapasitas biar ga full pas assign maajor agenda place
	string type;
	string gender; //untuk menentukan toilet untuk cewek/cowok/keduanya (kalau kosong)
	string posisi;
	string nama_gedung;
	string nama_ruang;
	string fakultas;
	list<Individual> Individuals_inside;
	list<map<int,int>> cek_dosen;
	list<map<int,int>> cek_penuh;
	int agen4;
	rgb color <- #gray  ;
	aspect geom {
		//draw shape color: color;
		int total_agen <- first_capacity - capacity; 
		int total_infected <- length(Individuals_inside where (each.stat_covid = "infected"));
		float percentage <- total_infected/total_agen;
		if (percentage < 0.02){
			draw shape color: color;
		} else if (percentage >= 0.02) and (percentage < 0.15){
			draw shape color: #orange;
		} else if (percentage >= 0.15){
			draw shape color: #red;
		}
		highlight self color: #yellow;
	}
}

species Boundary {
	aspect geom {
		draw shape color: #turquoise;
	}
}

species Roads {
	rgb color <- #black ;
	aspect geom {
		draw shape color: color;
	}
}


