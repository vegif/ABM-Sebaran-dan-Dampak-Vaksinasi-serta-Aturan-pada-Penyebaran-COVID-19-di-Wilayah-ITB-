/**
* Name: ParameterVegi
* Based on the internal empty template. 
* Author: Asus
* Tags: 
*/


model TugasAkhirVegi

import "Agen.gaml"
/* Insert your model definition here */

global{
	//Input Parameter
	int num_population; //Initial population
	int num_agen; //Initial family, input from user
	float num_init_percentage_infected;
	int num_init_infected;
	float num_init_percentage_vaccination; //persentase populasi yang tervaksinasi
	int num_init_vaccination; //jumlah populasi yang tervaksinasi
	int lockdown_threshold; //threshold jumlah terkonfirmasi sebelum terjadi lockdown
	float activity_reduction_lockdown; //persen pengurangan aktivitas jika diberlakukan lockdown di dalam kampus
	float test_accuracy; //cari referensi data 
	float contact_tracing_effectiveness; //Input from user
	float obedience; //cari referensi data
	float kondisi_kapasitas;
	float vaccination_efficacy;

	float threshold_positivity_rate; //input dari user
	int durasi_pembatasan; //input dari user
	int skema_pembatasan; //0 gaada skema pembatasan, 1 ada skema pembatasan luring atau daring, 2 ada skema pembatasan luring dan hybrid
						  //input dari user
						  
	int positivity_rate;
	bool pembatasan <- false;
	int count_durasi_pembatasan <- 0;
	
	//Pembagian Religion 
	float proba_muslim <- 0.7118; 
	float proba_hindu <- 0.0119;
	float proba_buddha <- 0.0250;
	float proba_protestan <- 0.1626;
	float proba_katolik <- 0.0824;
	float proba_konghuchu <- 0.0002;
	list<float> proba_religion <- [ //0=muslim, 1=hindu, 2=budha, 3=protestan, 4=katolik, 5=konghuchu
		proba_muslim, proba_hindu, proba_buddha,
		proba_protestan, proba_katolik, proba_konghuchu
	];
	
	//TIME DIVISION
	list<int> morning <- [7,8,9,10];
	list<int> daytime <- [11,12,13,14];
	list<int> evening <- [15,16,17,18];
	list<int> night <- [19,20,21,22];
	list<int> midnight <- [23,0,1,2,3,4,5,6];
	list<list<int>> time_of_day <- [morning, daytime, evening, night];
	
	//BEHAVIORAL PARAMETERS
	float proba_test <- 0.95; //Kemungkinan test
	float proba_activity_morning <-0.15;
	float proba_activity_daytime <-0.25;
	float proba_activity_evening <-0.325;
	float proba_activity_night <-0.05;
	list<float> proba_activities <- [
		proba_activity_morning,
		proba_activity_daytime,
		proba_activity_evening,
		proba_activity_night
	];
	float activity_reduction_factor <- 0.0;
	float mask_usage_proportion <- 0.75; //Ga sesuai sumber atau sumbernya dari paper di grup
	float infection_reduction_factor <- 0.1; //https://ejournal.upi.edu/index.php/image/article/download/24189/pdf
	float proportion_quarantined_transmission <- 0.1; 
	
	//Aturan PSBB
	int indikator1 <- 0;
	int indikator3 <- 0;
	
	//float test_accuracy;
	float sensitivity_pcr <- 0.943; //Data from journal
	float specificity_pcr <- 0.959; //Data from journal
	float sensitivity_rapid <- 0.775; //Data from journal
	float specificity_rapid <- 0.87; //Data from journal
	float quarantine_obedience <- 0.73; //Initial obedience from data in journal
	float mask_obedience <- 0.81; //Initial obedience from data in journal
	float mask_effectiveness <- 0.77; //sumber?
	int simulation_days; //Jumlah hari simulasi 
	
	//Parameter Epidemiologis
	map<list<int>,float> asymptomic_distribution <- [
	//Kemungkinan asimptomp berdasarkan umur
		 
		[0,19]::0.701,
		[20,29]::0.626,
		[30,39]::0.596,
		[40,49]::0.573,
		[50,59]::0.599,
		[60,69]::0.616,
		[70,100]::0.687
	];
	
	map<list<int>, list<float>> days_diagnose <- [
		/*
		 * Tipe data berbentuk map, yang memetakan rentang usia
		 * dengan parameter distribusi probabilitas.
		 */
		 
		[1,9]::[3.0,1.2],
		[10,19]::[5.0,1.81],
		[20,29]::[5.0,0.89],
		[30,39]::[4.0,0.64],
		[40,49]::[3.0,0.87],
		[50,59]::[2.0,0.84],
		[60,69]::[2.0,0.89],
		[70,100]::[2.0,0.97]
	];
	
	map<list<int>, list<float>> days_symptom_until_recovered <- [
		/*
		 * Tipe data berbentuk map, yang memetakan rentang usia
		 * dengan parameter distribusi probabilitas.
		 */
		 
		[1,9]::[17.65,1.2],
		[10,19]::[19.35,1.81],
		[20,29]::[19.25,0.89],
		[30,39]::[19.25,0.64],
		[40,49]::[21.7,0.87],
		[50,59]::[22.45,0.84],
		[60,69]::[22.95,0.89],
		[70,100]::[24.4,0.97]
	];
	
	map<list<int>,list<float>> susceptibility <- [ //Kerentanan
		/*
		 * Tipe data berbentuk map, yang memetakan rentang usia
		 * dengan parameter distribusi probabilitas.
		 */
		 
		[1,9]::[0.395,0.082],
		[10,19]::[0.375,0.067],
		[20,29]::[0.79,0.104],
		[30,39]::[0.865,0.082],
		[40,49]::[0.8,0.089],
		[50,59]::[0.82,0.089],
		[60,69]::[0.88,0.074],
		[70,100]::[0.74,0.089]
	];
	
	map<list<int>,int> incubation_distribution <- [ 
	//Distribusi periode inkubasi berdasarkan umur, rata2 4-5 hari bisa dicari lagi
		[0,14]::3,
		[15,29]::5,
		[30,44]::4,
		[45,59]::3,
		[60,74]::2,
		[75,89]::2,
		[89,100]::2
	];
}