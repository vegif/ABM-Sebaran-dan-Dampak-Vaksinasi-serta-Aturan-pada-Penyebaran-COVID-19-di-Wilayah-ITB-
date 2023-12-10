/**
* Name: ReflexGlobalVegi
* Based on the internal empty template. 
* Author: Asus
* Tags: 
*/


model TugasAkhirVegi

/* Insert your model definition here */

import "Init.gaml"
import "Agen.gaml"
import "Parameter.gaml"

global {
	int num_suspect <- 0;
	int num_probable <- 0;
	int num_confirmed <- 0;
	int num_discarded <- 0;
	int num_discovered <- 0;
	int num_recovered <- 0;
	int num_death <- 0;
	int num_positive <- 0; //Real (Sebagai Tuhan)
	
	int confirmed_today <- 0;
	int positive_today <- 0;
	int recovered_today <- 0;
	int death_today <- 0;
	
	int positive_yesterday <- 0;
	int confirmed_yesterday <- 0;
	int recovered_yesterday <- 0;
	
	int recovered_temp <- 0;
	int death_temp <- 0;
	int confirmed_temp <- 0;
	
	
	//setiap jam setelah agen enter building, nanti dicek masing2 building
	//yang paling banyak siapa (length meet nya) nah itu di include jadi meet today
	reflex check_meet when: ((current_hour < 20) and (current_hour > 5)){
		list<Building> temp_building <- Building where (each.type in ["RK","LB","KU","KA","MA","TO"]);
		ask temp_building{
			list<Individual> cek_individu <- self.Individuals_inside;
			ask cek_individu{ //coba cek masing-masing agen individu, siapa yang ketemunya paling banyak
				if (terbatas = true){
					//do nothing
				} else if (terbatas = false){
					temp_meet <- temp_meet + cek_individu;
				}
			}
			
			ask cek_individu{ //untuk ngehapus ketemu diri sendiri
				if (terbatas = true){
					//do nothing
				} else if (terbatas = false){
					temp_meet >> self;
				}
			}
		}
	}
	
	//Update data klinis dilakukan setiap jam 0. Karena jam 1 status kampus dievaluasi dan jam 0 data akan di-Display pada grafik di experiment.gaml
	reflex update_data when: (current_hour = 0) and (current_day > 0){
							
		num_suspect <- Individual count ((each.stat_covid in "suspect") and (each.live = 1));
		num_probable <- Individual count (each.stat_covid in "probable");
		num_confirmed <- Individual count ((each.stat_covid in "confirmed") and (each.live = 1)); 
		num_discarded <- Individual count (each.stat_covid in "discarded");
		num_recovered <- Individual count (each.stat_covid in "recovered" and (each.live = 1)); 
		num_death <- Individual count (each.stat_covid in "death"); 
		num_positive <- Individual count ((each.covid_stat in "infected") and (each.live = 1));
		
		confirmed_today <- Individual count (each.stat_covid in "confirmed" and each.confirm_period < 24); 
		positive_today <- Individual count (each.covid_stat in ["infected"] and (each.infection_period-each.incubation_period+24) < 24 and (each.infection_period-each.incubation_period+24) >= 0 and each.live = 1);
		recovered_today <-  Individual count (each.stat_covid in "recovered" and each.recovered_period < 24 and each.live = 1); 
		death_today <- num_death - death_temp;
		
		positive_yesterday <- positive_today;
		confirmed_yesterday <- confirmed_today;
		recovered_temp <- num_recovered;
		recovered_yesterday <- recovered_temp;
		death_temp <- num_death;//
		confirmed_temp <- num_confirmed;
		
		//saat jumlah covid diatas threshold, maka pembatasan berlaku (berubah menjadi true)
		//tapi tidak berlaku jika aturan pembatasan sedang berlangsung
		list<Individual> agen_hidup <- Individual where (each.live = 1);
		positivity_rate <- int(length(agen_hidup)*threshold_positivity_rate);
		if ((num_confirmed >= positivity_rate) and (pembatasan = false)){
			pembatasan <- true;
		}
	}
	
	reflex check_aturan_pembatasan when: ((current_hour = 1) and (current_day > 0) and (pembatasan = true)){
		if (skema_pembatasan = 1){ 
			list<Individual> agen_hidup <- Individual where (each.live = 1);	
			if count_durasi_pembatasan = 0{ //perubahan aturan pembatasan dari luring ke full daring
				ask agen_hidup{
					terbatas <- true; //semua orang yang masi idup, gabisa ke kantor
				}
				count_durasi_pembatasan <- count_durasi_pembatasan + 1;
			} else if count_durasi_pembatasan < durasi_pembatasan{ //sedang berlangsung pembatasan
				count_durasi_pembatasan <- count_durasi_pembatasan + 1;
			} else if count_durasi_pembatasan = durasi_pembatasan{ //kalau sudah mencapai threshold durasi aturan pembatasan
				if (num_confirmed >= positivity_rate){ //kalau jumlah positif masih diatas threshold maka tetep tutup kampus utk cycle kedua
					count_durasi_pembatasan <- 0;
					pembatasan <- true; //kampus tetap di tutup
				} else if (num_confirmed < positivity_rate){ //kalau jumlah positif sudah dibawah threshold maka kampus buka kembali
					pembatasan <- false;
					ask agen_hidup{
						terbatas <- false;
					}
					count_durasi_pembatasan <- 0;
				}
			}	
		}
		if (skema_pembatasan = 2){
			list<Individual> agen_hidup <- Individual where (each.live = 1);
			list<Individual> temp_mahasiswa <- agen_hidup where (each.status_agen = 1);	
			if count_durasi_pembatasan = 0{ //perubahan aturan pembatasan dari luring ke hybrid
				ask temp_mahasiswa{ //pastikan semua keadaan mahasiswa tidak ada pembatasan dan ada kemungkinan
									//perubahan mahasiswa yang boleh ke kampus setelah cycle pertama (pembatasan cycle kedua yang berurutan)
					terbatas <- false;
				}
				int pengurangan_mahasiswa <- length(temp_mahasiswa) div 50; //50% dari mahasiswa dirumahkan
				ask pengurangan_mahasiswa among temp_mahasiswa{
					terbatas <- true;
				}
				count_durasi_pembatasan <- count_durasi_pembatasan + 1;
			} else if count_durasi_pembatasan < durasi_pembatasan{
				count_durasi_pembatasan <- count_durasi_pembatasan + 1;
			} else if count_durasi_pembatasan = durasi_pembatasan{
				if (num_confirmed >= positivity_rate){
					count_durasi_pembatasan <- 0;
					pembatasan <- true;
				} else if (num_confirmed < positivity_rate){
					pembatasan <- false;
					ask temp_mahasiswa{
						terbatas <- false;
					}
					count_durasi_pembatasan <- 0;
				}
			}
		}
	}
}
