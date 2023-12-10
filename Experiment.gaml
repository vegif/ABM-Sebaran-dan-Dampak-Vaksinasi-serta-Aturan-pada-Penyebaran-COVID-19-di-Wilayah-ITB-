/**
* Name: ExperimentVegi
* Based on the internal empty template. 
* Author: Asus
* Tags: 
*/


model TugasAkhirVegi

import "Init.gaml"
import "Agen.gaml"
import "Reflex_Global.gaml"

global {
	init {
		do user_inputs;
		do init_building;
		do population_generation;
		do delete_individual;
		do major_agenda;
		
		num_init_infected <- int((num_init_percentage_infected*num_agen)/10.0); //angka dibawah 1% maka ga terbaca by sistem, jadi harus kasi pembagi biar aman
		list<Individual> agen_hidup <- Individual where (each.live=1);
		ask num_init_infected among agen_hidup{
			covid_stat <- "exposed";
		}
		
		num_init_vaccination <- int(num_init_percentage_vaccination*num_agen);
		ask num_init_vaccination among agen_hidup{
			vaccination <- true;
		}
		
		ask Individual{
			current_place <- home;
			location <- any_location_in (current_place);
			current_place.capacity <- current_place.capacity - 1;
			loop i from: 0 to: simulation_days {
				meet[i] <- [];
			}
		}
	}	
	
	action user_inputs { 
		map<string,unknown> values1 <- user_input("Masukkan jumlah hari yang akan disimulasikan.",[enter("Hari",60)]);
		simulation_days <- int(values1 at "Hari");
		
		map<string,unknown> values2 <- user_input("Masukkan jumlah Agen/Individu di pemodelan.",[enter("Individu",20000)]);
		num_agen <- int(values2 at "Individu");
		
		map<string,unknown> values3 <- user_input("Masukkan persentase individu dalam pemodelan terinfeksi di awal (masukkan angka persentase dalam pengali 10. Misal 1% maka diisi 10)",[enter("(%)",10)]); //1% dari warga kampus
		num_init_percentage_infected <- int(values3 at "(%)")/100.0;
		
		map<string,unknown> values4 <- user_input("Masukkan persentase Individu dalam pemodelan yang tervaksinasi.",[enter("(%)",50)]); 
		num_init_percentage_vaccination <- int(values4 at "(%)")/100.0;
		
		map<string,unknown> values5 <- user_input("Masukkan angka efikasi vaksin.",[enter("(%)",95)]); 
		vaccination_efficacy <- int(values5 at "(%)")/100.0;
		
		map<string,unknown> values6 <- user_input("Masukkan persen efektivitas contact tracing.",[enter("(%)",75)]);
		contact_tracing_effectiveness <- int(values6 at "(%)")/100.0;
		
		map<string,unknown> values7 <- user_input("Masukkan persen efektivitas test.",[enter("(%)",90)]);
		test_accuracy <- int(values7 at "(%)")/100.0;
		
		map<string,unknown> values8 <- user_input("Masukkan persen kepatuhan orang2 secara umum.",[enter("(%)",70)]);
		obedience <- int(values8 at "(%)")/100.0;
		
		map<string,unknown> values9 <- user_input("Masukkan nilai threshold angka minimal positivity rate untuk memberlakukan pembatasan.",[enter("(%)",5)]); 
		threshold_positivity_rate <- int(values9 at "(%)")/100.0;
		
		map<string,unknown> values10 <- user_input("Masukkan durasi hari jika didiberlakukan pembatasan.",[enter("Hari",10)]);
		durasi_pembatasan <- int(values10 at "Hari");
		
		map<string,unknown> values11 <- user_input("Masukkan skema pembatasan yang akan dilakukan (0=tidak ada, 1=luring&daring, 2=luring&hybrid.",[enter("Skema",1)]);
		skema_pembatasan <- int(values11 at "Skema");
	}
	
	reflex stop_simulation when: (current_day = simulation_days) {
		do pause;
	}
}

experiment run_experiment type: gui {
	bool allow_rewrite <- true;
	string filename_1 <- "save_data_klinis_harian_" + cur_date_str + ".csv";
	string filename_2 <- "save_data_klinis_total_" + cur_date_str + ".csv";
	 
	//Reflex utk handling data yang akan menjadi output pada file .csv
	reflex output_file when: current_hour = 0 {
		save [string(current_day), positive_today, confirmed_today, recovered_today, death_today] to: filename_1 type:csv rewrite:allow_rewrite;
		allow_rewrite <- false;
		save [string(current_day), num_confirmed, num_positive, num_suspect, num_probable, num_discarded, num_recovered, num_death] to: filename_2 type:csv rewrite:allow_rewrite;
		allow_rewrite <- false;
	}
	
	string simulation_name <- "Hari" + hari_apa + "jam" + current_hour update: "Hari" + hari_apa + "jam" + current_hour;
	output {
		layout #split consoles:false editors:false navigator:false;
		
		display view draw_env: false type:opengl {
			species Boundary aspect: geom;
			species Roads aspect: geom;
			species Building aspect: geom;
			species Individual aspect: circle;
			graphics title {
				//draw simulation_name color: #black anchor: #top_center;
				//draw legend color: #black anchor: #bottom_center; //error malah berantakan
			}
		}
		
		display chart_1 refresh:(current_hour = 0) {
			chart "Data Harian" type: xy background: #white axes: #black color:#black tick_line_color: #grey {
				data "Jumlah Individu yang sebenarnya positif pada hari ini" value: {current_day, positive_today} color: #orange line_visible: true;
				data "Jumlah Individu yang dinyatakan positif pada hari ini" value: {current_day, confirmed_today} color: #red line_visible: true;
				data "Jumlah Individu yang meninggal pada hari ini" value: {current_day, death_today} color: #green line_visible: true;
				data "Jumlah Individu yang sembuh pada hari ini" value: {current_day, recovered_today} color: #blue line_visible: true;
			}
		}
		
		display chart_2 refresh:(current_hour = 0){
			chart "Data Total Status" type: xy background: #white axes: #white color: #black tick_line_color: #grey {
				data "Jumlah Individu terinfeksi dalam kenyataannya" value: {cycle/24, num_positive} color: #black marker:false;
				data "Jumlah Individu terkonfirmasi hasil test" value: {cycle/24, num_confirmed} color: #red marker:false;	
				data "Jumlah Individu berstatus suspect" value: {cycle/24, num_suspect} color: #yellow marker:false;
				data "Jumlah Individu berstatus probable" value: {cycle/24, num_probable} color: #purple marker:false;
				data "Jumlah Individu berstatus discarded" value: {cycle/24, num_discarded} color: #blue marker:false;
			}
		}
		
		display chart_3 refresh:(current_hour = 0){
			chart "Data Sembuh dan Meninggal" type: xy background: #white axes: #white color: #black tick_line_color: #grey {
				data "Jumlah Individu yang sembuh" value: {cycle/24, num_recovered} color: #blue marker:false;
				data "Jumlah Individu yang meninggal" value: {cycle/24, num_death} color: #red marker:false;
			}
		}
	}
}
