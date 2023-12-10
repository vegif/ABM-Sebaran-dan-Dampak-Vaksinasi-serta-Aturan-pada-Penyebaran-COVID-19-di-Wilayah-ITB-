model TugasAkhirVegi
/* Insert your model definition here */

import "Agen.gaml"
import "Parameter.gaml"
import "Reflex_Global.gaml"

global {
	date cur_date <- #now; //assign tanggal hari ini
	string cur_date_str <- replace(string(cur_date),':','-'); //subtitusi variabel : dengan -
	int hours_elapsed <- 0 update: hours_elapsed + 1;
	int current_hour <- 0 update: (hours_elapsed) mod 24;
	int current_day_of_week <- 0 update: ((hours_elapsed) div 24) mod 7;
	string hari_apa <- int_to_day(current_day_of_week) update: int_to_day(current_day_of_week);
	int current_day <- 0 update: ((hours_elapsed) div 24);
	int previous_day <- 0;	
	int simulation_days; //varabel input jumlah hari simulasi di experiment.gaml
	
	string int_to_day (int x) {
		string str;
		switch x {
			match 0 {str <- "Senin";}
			match 1 {str <- "Selasa";}
			match 2 {str <- "Rabu";}
			match 3 {str <- "Kamis";}
			match 4 {str <- "Jumat";}
			match 5 {str <- "Sabtu";}
			match 6 {str <- "Minggu";}
		}
		return str;	
	}

	//inisiasi file building diluar action init_building karna markers fungsi envelope gabisa di dalam action
	file shp_buildings <- file("../includes/Bangunan/Building_ITB_Fix.shp"); 
	geometry shape <- envelope(shp_buildings); //Data from GIS	
	file shp_boundary <- file("../includes/Bangunan/Batas.shp"); //Data from GIS
	file shp_roads <- file("../includes/Bangunan/Jalan.shp"); //Data from GIS	
	
	//List Building
	map<string, list<Building>> buildings_per_activity; //jenis bangunan A dengan list bangunannya dari 1-x, map memetakan jenis bangunan ke semua bangunan yang sesuai.
	list<Building> livings;	// list akan diisi semua entitas Bangunan yang digolongkan rumah.
	list<Building> assign_agen4; //variabel tambahan untuk mengisi semua entitas bangunan yang bisa dijadikan tempat kerja oleh Status_Agen 4 (Others)
	
	action init_building { // Action untuk membuat entitas Boundary, Roads, dan Building.
		create Boundary from: shp_boundary;
		create Roads from: shp_roads;	
		create Building from: shp_buildings with: [type::string(read('KD_RUANG')), capacity::int(read('Capacity')), fakultas:: read('Fakultas'), 
			gender:: read('Gender'), posisi:: read('POSISI'), nama_ruang:: read('NM_RUANG'), nama_gedung::read('NM_GEDUNG')]{
			first_capacity <- capacity;
		}
		
		ask Building{ //Inisiasi
			loop i from:0 to: 6 {
				cek_dosen << [];
				cek_penuh << [];
			} 
			if (type in ["KA","MA","TO"]){ //utk memastikan setiap status_agen 4 berada pada ruangan yang berbeda 
				agen4 <- 1;
			} else if (type in["RK","LB","KU"]){
				agen4 <- 2;
			}
		}
		buildings_per_activity <- Building group_by (each.type); 
		livings <- Building where (each.type in ["TT"]); //diisi seluruh building yang TT
	}
	
	action population_generation {
	 	//Action untuk membuat populasi entitas Individual.
		int num_mahasiswa <- round(num_agen*0.84); 
		int num_dosen <- round(num_agen*0.07);
		int num_tendik <- round(num_agen*0.07);
		int num_others <- round(num_agen*0.02); //faktor pengali dihitung secara manual diluar pemodelan
	 
		create Individual number: num_mahasiswa{
			age <- rnd(14,25);			
			sex <- rnd(0,1);
			int tmp_fakultas <- rnd(1,12);
			switch tmp_fakultas {
				match 1 {fakultas <- "FITB";}
				match 2 {fakultas <- "FMIPA";}
				match 3 {fakultas <- "FSRD";}
				match 4 {fakultas <- "FTI";}
				match 5 {fakultas <- "FTMD";}
				match 6 {fakultas <- "FTTM";}
				match 7 {fakultas <- "FTSL";}
				match 8 {fakultas <- "SAPPK";}
				match 9 {fakultas <- "SBM";}
				match 10 {fakultas <- "SF";}
				match 11 {fakultas <- "SITH";}
				match 12 {fakultas <- "STEI";}
			}
			angkatan <- rnd(2018,2021);
			status_agen <- 1; //1 berarti mahasiswa
			live <- 1;
			home <- one_of(livings); 
			religion <- rnd_choice(["Muslim"::proba_muslim,"Hindu"::proba_hindu,"Buddha"::proba_buddha,
				"Protestan"::proba_protestan,"Katolik"::proba_katolik,"Konghuchu"::proba_konghuchu]);
	 	} 
	 	
	 	create Individual number: num_dosen {
			age <- rnd(25,65);
			sex <- rnd(0,1);
			int tmp_fakultas <- rnd(1,12);
			switch tmp_fakultas {
				match 1 {fakultas <- "FITB";}
				match 2 {fakultas <- "FMIPA";}
				match 3 {fakultas <- "FSRD";}
				match 4 {fakultas <- "FTI";}
				match 5 {fakultas <- "FTMD";}
				match 6 {fakultas <- "FTTM";}
				match 7 {fakultas <- "FTSL";}
				match 8 {fakultas <- "SAPPK";}
				match 9 {fakultas <- "SBM";}
				match 10 {fakultas <- "SF";}
				match 11 {fakultas <- "SITH";}
				match 12 {fakultas <- "STEI";}
			}
			status_agen <- 2; //2 berarti dosen
			live <- 1;
			home <- one_of(livings) ; 
			religion <- rnd_choice(["Muslim"::proba_muslim,"Hindu"::proba_hindu,"Buddha"::proba_buddha,
				"Protestan"::proba_protestan,"Katolik"::proba_katolik,"Konghuchu"::proba_konghuchu]);
		}
		
		create Individual number: num_tendik {
			age <- rnd(25,65);
			sex <- rnd(0,1);
			int tmp_fakultas <- rnd(1,12);
			switch tmp_fakultas {
				match 1 {fakultas <- "FITB";}
				match 2 {fakultas <- "FMIPA";}
				match 3 {fakultas <- "FSRD";}
				match 4 {fakultas <- "FTI";}
				match 5 {fakultas <- "FTMD";}
				match 6 {fakultas <- "FTTM";}
				match 7 {fakultas <- "FTSL";}
				match 8 {fakultas <- "SAPPK";}
				match 9 {fakultas <- "SBM";}
				match 10 {fakultas <- "SF";}
				match 11 {fakultas <- "SITH";}
				match 12 {fakultas <- "STEI";}
			}
			status_agen <- 3; //3 berarti tendik
			live <- 1;
			home <- one_of(livings) ; 
			religion <- rnd_choice(["Muslim"::proba_muslim,"Hindu"::proba_hindu,"Buddha"::proba_buddha,
				"Protestan"::proba_protestan,"Katolik"::proba_katolik,"Konghuchu"::proba_konghuchu]);
		}
		
		create Individual number: num_others {
			age <- rnd(14,65);			
			sex <- rnd(0,1);
			status_agen <- 4; //4 berarti others
			live <- 1;
			home <- one_of(livings) ; 
			religion <- rnd_choice(["Muslim"::proba_muslim,"Hindu"::proba_hindu,"Buddha"::proba_buddha,
				"Protestan"::proba_protestan,"Katolik"::proba_katolik,"Konghuchu"::proba_konghuchu]);
		 }	 
		 
		num_population <- length (Individual);
	}

	action delete_individual{
		int temp<- 0;
		list<Individual> Mahasiswa <- Individual where (each.status_agen = 1);
		ask Mahasiswa{
			if (fakultas != "STEI"){
				live <- 0;
				temp <- temp+1;
				home <- one_of(Building where (each.type in ["DE"]));
			}			
		}
		
		list<Individual> Dosen <- Individual where (each.status_agen = 2);
		ask Dosen{
			if (fakultas = "STEI") or (fakultas = "FMIPA"){
				//do nothing
			} else {
				live <- 0;
				temp <- temp+1;
				home <- one_of(Building where (each.type in ["DE"]));
			}
		}
		
		list<Individual> Tendik <- Individual where (each.status_agen = 3);
		ask Tendik{
			if (fakultas = "STEI") or (fakultas = "FMIPA"){
				//do nothing
			} else {
				live <- 0;
				temp <- temp+1;
				home <- one_of(Building where (each.type in ["DE"]));				
			}
		}
		
		num_agen <- num_agen - temp; //total agen terbaru untuk masuk ke dalam pemodelan~
	}
	
	action major_agenda{	
		ask Individual where (each.live = 1){
			list<Building> working_places;
			// inisiasi list agenda
			loop i from: 0 to: 6 {
				agenda_week << [];
				jadwal_kelas << [];
			}
			
			if (status_agen = 1){ 
				//baru assign jadwal kelas, blm nge-assign beres kelas agen kemana
				//major agenda place gaada karna ya pindah2 klas :(
				loop d over: [0,1,2,3,4]{
					int start_hour <- 7;
					int end_hour <- 18;
					//mahasiswa paling pagi kelas jam 7 dan paling telat pulang jam 18

					agenda_week[d][end_hour] <- self.home;
				}
			}
			
			if (status_agen = 2){ 			
				//dosen setiap pagi harus ambil absen ke kantor mereka, maka setiap pagi pasti ke kantor
				working_places <- shuffle(Building where (each.type in ["KU"]));
				Building temp_working_places <- one_of(working_places); 
				loop while: ((temp_working_places.fakultas != fakultas) and (temp_working_places.fakultas != "UMUM")){ //or ((temp_working_places.tempcapacity - 1) <= (temp_working_places.capacity)){
					temp_working_places <- one_of(working_places);
				}
				
				major_agenda_place <- temp_working_places;
					
				loop d over: [0,1,2,3,4]{
					int start_hour <- 6; //dosen mulai ngajar jam 7, pasti ke ruangannya sebelum itu
					int end_hour <- 18;
					agenda_week[d][start_hour] <- major_agenda_place;
					agenda_week[d][end_hour] <- self.home;
				}
				
			}
						
			if (status_agen = 3){				
				//tendik hari-hari pasti di dalam kantor aja
				working_places <- shuffle(Building where (each.type in ["KU","LB"]));
				Building temp_working_places <- one_of(working_places);
				
				loop while: ((temp_working_places.fakultas != fakultas) and (temp_working_places.fakultas != "UMUM")){ //or ((temp_working_places.tempcapacity - 1) <= (temp_working_places.capacity)){
					temp_working_places <- one_of(working_places); 
				}
				
				major_agenda_place <- temp_working_places;
				
				loop d over: [0,1,2,3,4]{
					int start_hour <- 7;
					int end_hour <- 17;
					
					agenda_week[d][start_hour] <- temp_working_places;
					agenda_week[d][end_hour] <- self.home;
				}			
				
			}
			if (status_agen = 4){			
				//para pekerja lainnya, pasti akan stay di dalam tempat mereka bekerja
				assign_agen4 <- Building where (each.agen4 > 0);
				assign_agen4 <- shuffle(assign_agen4);
				Building temp_working_places <- one_of(assign_agen4);
				major_agenda_place <- temp_working_places;
				string temp <- temp_working_places.type;
				temp_working_places.agen4 <- temp_working_places.agen4-1;				
				
				if (temp = "KA"){ //penjaga kantin
					loop d over: [0,1,2,3,4]{
						int start_hour <- 6;
						int end_hour <- 18;
						
						agenda_week[d][start_hour] <- temp_working_places;
						agenda_week[d][end_hour] <- self.home;
					}			
				}
				else if ((temp = "TO") or (temp = "MA")){ //bersihin toilet dan mushalla
					loop d over: [0,1,2,3,4]{
						int start_hour_1 <- 7; //berisihin pagi
						int start_hour_2 <- 19; //berisihin sore
						
						agenda_week[d][start_hour_1] <- temp_working_places;
						agenda_week[d][start_hour_1+1] <- self.home;
						agenda_week[d][start_hour_2] <- temp_working_places;
						agenda_week[d][start_hour_2+1] <- self.home;
					}					
				}				
				else if ((temp = "RK") or (temp = "LB") or (temp = "KU")){
					//bersih-bersih ruangan kelas, lab, dan kantor umum
					loop d over: [0,1,2,3,4]{
						int start_hour_1 <- 6; //berisihin pagi
						int start_hour_2 <- 19; //bersihin sore
						
						agenda_week[d][start_hour_1] <- temp_working_places;
						agenda_week[d][start_hour_1+1] <- self.home;
						agenda_week[d][start_hour_2] <- temp_working_places;
						agenda_week[d][start_hour_2+1] <- self.home;
					}					
				}		
			}
		}
		
		
		list<Building> temp_ruangan <- Building where (each.type in ["RK"]);
		list<Building> ruangan_stei <- temp_ruangan where (each.fakultas in ["STEI"]);
		list<Building> ruangan_TPB <- temp_ruangan where (each.fakultas in ["TPB"]); 
		list<Building> ruangan_stei_large <- ruangan_stei where (each.first_capacity >= 60);
		list<Building> ruangan_TPB_large <- ruangan_TPB where (each.first_capacity >= 60);
		

		list<Individual> mahasiswa <- Individual where (each.status_agen in [1] and each.live = 1); 
		list<Individual> mahasiswa_stei <- mahasiswa where (each.fakultas in ["STEI"]); 
		int temp_golongan <- 1;
		
		loop d over: [2018,2019,2020,2021]{ //angkatan mahasiswa yang ada
			int max_sks_wajib;
			list<Individual> mahasiswa_stei_angkatan <- mahasiswa_stei where (each.angkatan in[d]); 
			int num_mahasiswa_stei_angkatan <- length(mahasiswa_stei_angkatan); 
			
			if d = 2018{ //tingkat akhir
				max_sks_wajib <- 8;
			}
			else if d != 2018{ //bukan tingkat akhir
				max_sks_wajib <- 18;
			}			
			loop e over: [1,2,3,4,5,6]{ //menyatakan ada 6 golongan yang tersedia
				int assign_sks <- 0;
				int num_mahasiswa_stei_angkatan_per_golongan <- num_mahasiswa_stei_angkatan div 6; 
				list<map<int,int>> cek_jadwal_kosong;
				list<map<int, Building>> temp_agenda_week_mahasiswa; //variabel sementara utk membuat jadwal di setiap golongan
				loop i from: 0 to: 6 { //inisiasi 
					cek_jadwal_kosong << [];
					temp_agenda_week_mahasiswa << [];
				}
			
				loop while: (assign_sks < max_sks_wajib){ //assign seluruh jadwal seminggu utk masing2 golongan
					int sks <- 1; //assign jadwal dibuat per jam karena biar bisa mastiin jadwal yang di assign kosong
					int cek_hari <- rnd(0,4);
					int cek_jam <- rnd(7,17);
					loop while: (cek_jadwal_kosong[cek_hari][cek_jam] = 1){
						cek_hari <- rnd(0,4);
						cek_jam <- rnd(7,17);						
					}
					cek_jadwal_kosong[cek_hari][cek_jam] <- 1;
					assign_sks <- assign_sks + sks;
					
					if d = 2021{
						
						Building temp <- one_of(ruangan_TPB_large); //assign ruangan ke dalam jadwal yang dibuat
						loop while: (temp.cek_penuh[cek_hari][cek_jam] = 1){ 
						//juga cek ruangan pada jadwal tersebut udah ada jadwal kelas apa blm
							temp <- one_of(ruangan_TPB_large);
						}
						temp.cek_penuh[cek_hari][cek_jam] <- 1; 
						//nge-assign di jadwal terkait udah ada jadwal kelas dari golongan tertentu
						temp_agenda_week_mahasiswa[cek_hari][cek_jam] <- temp;
						
					} else { 
						
						Building temp <- one_of(ruangan_stei_large); //assign ruangan ke dalam jadwal yang dibuat
						loop while: (temp.cek_penuh[cek_hari][cek_jam] = 1){// 
						//juga cek ruangan pada jadwal tersebut udah ada jadwal atau belum
							temp <- one_of(ruangan_stei_large);
						}
						temp.cek_penuh[cek_hari][cek_jam] <- 1;
						temp_agenda_week_mahasiswa[cek_hari][cek_jam] <- temp;
					}		
				}
				
				loop while: (num_mahasiswa_stei_angkatan_per_golongan != 0){
					list<Individual> temp_mahasiswa <- mahasiswa_stei_angkatan where (each.golongan in[0]); //utk ngurangin iterasi, biar ga ngecek seluruh mahasiswa stei angkatan terus
					Individual assign_mahasiswa <- one_of(temp_mahasiswa);
					assign_mahasiswa.jadwal_kelas <- cek_jadwal_kosong;
					assign_mahasiswa.agenda_week <- temp_agenda_week_mahasiswa;
					assign_mahasiswa.golongan <- temp_golongan;
					num_mahasiswa_stei_angkatan_per_golongan <- num_mahasiswa_stei_angkatan_per_golongan-1;
				}
				temp_golongan <- temp_golongan+1; //untuk ngebuat berbagai golongan dengan jadwal yang sama xixi
			}
		}
		//Assign SKS pilihan ke jadwal mahasiswa hehehe	(sampai sks nya full satu semester maksimal 24)
		
		ask ruangan_stei_large{
			list<Individual> dosen <- Individual where (each.status_agen in [2]);
			list<Individual> dosen_stei <- dosen where (each.fakultas in ["STEI"]); 
			
			loop d over: [0,1,2,3,4]{
				int temp_hour <- 7;
				loop while: (temp_hour < 18){
					if (cek_penuh[d][temp_hour] = 1){
						Individual temp_dosen <- one_of(dosen_stei);
						loop while: (temp_dosen.jadwal_kelas[d][temp_hour] = 1) or (temp_dosen.durasi_kelas >= 16){
							temp_dosen <- one_of(dosen_stei);
						}
						
						temp_dosen.jadwal_kelas[d][temp_hour] <- 1;
						temp_dosen.agenda_week[d][temp_hour] <- self;
						temp_dosen.durasi_kelas <- temp_dosen.durasi_kelas+1;
						cek_dosen[d][temp_hour] <- 1; //verifikasi diruangan tersebut ada dosen pada jadwal yang dipilih
					}
					temp_hour <- temp_hour+1;
				}
			}
		}
		
		ask ruangan_TPB_large{
			list<Individual> dosen <- Individual where (each.status_agen in [2]);
			list<Individual> dosen_tpb <- dosen where (each.fakultas in ["FMIPA"]); 
			
			loop d over: [0,1,2,3,4]{
				int temp_hour <- 7;
				loop while: (temp_hour < 18){
					if (cek_penuh[d][temp_hour] = 1){
						Individual temp_dosen <- one_of(dosen_tpb);
						loop while: (temp_dosen.jadwal_kelas[d][temp_hour] = 1) or (temp_dosen.durasi_kelas >= 16){
							temp_dosen <- one_of(dosen_tpb);
						}
						
						temp_dosen.jadwal_kelas[d][temp_hour] <- 1;
						temp_dosen.agenda_week[d][temp_hour] <- self;
						temp_dosen.durasi_kelas <- temp_dosen.durasi_kelas+1;
						cek_dosen[d][temp_hour] <- 1; //verifikasi diruangan tersebut ada dosen pada jadwal yang dipilih
					}
					temp_hour <- temp_hour+1;
				}
			}
		}
	}
}