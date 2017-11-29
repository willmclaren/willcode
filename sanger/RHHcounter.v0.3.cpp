#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <sstream>
#include <algorithm>

#include "randomc.h"
#include "mother.cpp"

using namespace std;

// constructors
bool isHet(string geno);

map<int, int> runSims(map<int, int> * dist, int numSamples, int numSims);

std::string IntToString ( int number ) {
	std::ostringstream oss;

	// Works just like cout
	oss<< number;

	// Return the underlying string
	return oss.str();
}


// data structures
struct SNP {
	string id;
	string chr;
	int pos;
	string rareHet;
	string rareHom;
	bool include;
};

struct intCmp {
	bool operator()( const int s1, const int s2 ) const {
		return (s1 < s2) == true;
	}
};

struct strCmp {
	bool operator()( const char* s1, const char* s2 ) const {
		return strcmp(s1, s2) < 0;
	}
};


// main function
int main(int argc, char* argv[]) {
	
	time_t rawtime;
	time(&rawtime);
	cout << "RHHcounter v0.3" << endl << asctime(localtime(&rawtime)) << endl;

	
	// Define chromosome sizes
	map<string, int> maxPos;
	maxPos["1"] = 247249719;
	maxPos["2"] = 242951149;
	maxPos["3"] = 199501827;
	maxPos["4"] = 191273063;
	maxPos["5"] = 180857866;
	maxPos["6"] = 170899992;
	maxPos["7"] = 158821424;
	maxPos["8"] = 146274826;
	maxPos["9"] = 140273252;
	maxPos["10"] = 135374737;
	maxPos["11"] = 134452384;
	maxPos["12"] = 132349534;
	maxPos["13"] = 114142980;
	maxPos["14"] = 106368585;
	maxPos["15"] = 100338915;
	maxPos["16"] = 88827254;
	maxPos["17"] = 78774742;
	maxPos["18"] = 76117153;
	maxPos["19"] = 63811651;
	maxPos["20"] = 62435964;
	maxPos["21"] = 46944323;
	maxPos["22"] = 49691432;
	maxPos["X"] = 154913754;
	maxPos["Y"] = 57772954;

	
	string usage = "Usage: RHHcounter [arguments] map_file ped_file\nType \"RHHcounter --help\" for help on running the program";

	// DEAL WITH ARGUMENTS //
	/*---------------------*/
	
	int curr = 1;
	
	// set defaults
	char* outStem = "RHHcounter";
	float callrate = 0.9;
	float hetFrac = 0.005;
	float homFrac = 0.002;
	float lHetFrac = 0;
	int resHom = 0;
	int numSims = 1000;
	bool fullOutput = false;
	int hetCount = 99999;
	int homCount = 99999;
	
	vector<int> distances;
	vector<string> distnames;
	char * chunk;
	char * snpListFileName = "none";
	char * sampleListFileName = "none";
	int prevdist = 0;
	

	if(argc > 1) {
	
		// HELP
		if(!strcmp(argv[curr], "-h") || !strcmp(argv[curr], "--help")) {
			cout << "RHHcounter - outlier detection in genome-wide genotyping studies" << endl << endl;
			cout << usage << endl << endl;
			cout << "List of options:" << endl;
			cout << "-o\tSet the stem filename for output files [default: RHHcounter]" << endl;
			cout << "-c\tSet the sample call rate cut-off [default: 0.9]" << endl;
			cout << "-het\tSet the threshold fraction for rare heterozygote classification [default: 0.005]" << endl;
			cout << "-hom\tSet the threshold fraction for rare homozygote classification [default: 0.002]" << endl;
			cout << "-hetc\tSet the threshold count for rare heterozygote classification [default: Not used]" << endl;
			cout << "-homc\tSet the threshold count for rare homozygote classification [default: Not used]" << endl;
			cout << "-sims\tSet the number of simulations to be run [default: 1000]" << endl;
			cout << "-d\tSet a list of base-pair distances to perform distance reduction [default: Not used]" << endl;
			cout << "-m\tSpecify a file containing a list of markers not to use in analysis [default: Not used]" << endl;
			cout << "-s\tSpecify a file containing a list of sample IDs to exclude from analysis [default: Not used]" << endl;
			cout << "-f\tGenerates additional output, identifying all rare hets/homs in all samples [default: Not used]" << endl << endl;
			cout << "Examples:" << endl;
			cout << "> RHHcounter -f -o myresults mydata.map mydata.ped" << endl;
			cout << "> RHHcounter -sims 5000 -het 0.004 -d 1000000,5000000 -o myresults mydata.map mydata.ped" << endl;
			return 0;
		}
		
		// OTHER ARGUMENTS
		else if(!strcmp(((string) argv[curr]).substr(0,1).c_str(), "-")) {
			for(curr = 1; curr<(argc-2); curr++) {
			
				// output stem
				if(!strcmp(argv[curr], "-o")) {
					curr++;
					outStem = argv[curr];
					cout << "Output stem set to " << outStem << endl;
				}
				
				// het threshold
				else if(!strcmp(argv[curr], "-het")) {
					curr++;
					hetFrac = atof(argv[curr]);
					
					// sanity checks
					if((hetFrac <= 0) || (hetFrac >= 1)) {
						cout << endl << "ERROR: Threshold for rare hets cannot be set to " << hetFrac << endl;
						return 64;
					}
					
					cout << "Threshold for rare heterozygotes set to " << hetFrac << endl;
				}
				
				// hom threshold
				else if(!strcmp(argv[curr], "-hom")) {
					curr++;
					homFrac = atof(argv[curr]);
					
					// sanity checks
					if((homFrac <= 0) || (homFrac >= 1)) {
						cout << endl << "ERROR: Threshold for rare homs cannot be set to " << hetFrac << endl;
						return 64;
					}
					
					cout << "Threshold for rare homozygotes set to " << homFrac << endl;
				}
				
				// lower het threshold
				else if(!strcmp(argv[curr], "-hetl")) {
					curr++;
					lHetFrac = atof(argv[curr]);
					
					// sanity checks
					if((lHetFrac < 0) || (lHetFrac >= 1)) {
						cout << endl << "ERROR: Lower threshold for rare hets cannot be set to " << lHetFrac << endl;
						return 64;
					}
					
					cout << "Lower threshold for rare heterozygotes set to " << lHetFrac << endl;
				}
				
				// restrict hom counts for rare het?
				else if(!strcmp(argv[curr], "-nhom")) {
					resHom = 99999;
					
					cout << "No restrictions on hom counts for rare het classification" << endl;
				}
				
				// alternative - het count threshold
				else if(!strcmp(argv[curr], "-hetc")) {
					curr++;
					hetCount = atoi(argv[curr]);
					
					// sanity checks
					if(hetCount < 1) {
						cout << endl << "ERROR: Threshold for rare heterozygote count cannot be set to " << hetCount << endl;
					}
					
					cout << "Threshold for rare heterozygote count set to " << hetCount << endl;
				}
				
				// alternative - het count threshold
				else if(!strcmp(argv[curr], "-homc")) {
					curr++;
					homCount = atoi(argv[curr]);
					
					// sanity checks
					if(homCount < 1) {
						cout << endl << "ERROR: Threshold for rare homozygote count cannot be set to " << homCount << endl;
					}
					
					cout << "Threshold for rare homozygote count set to " << homCount << endl;
				}
				
				// number of simulations
				else if(!strcmp(argv[curr], "-sims")) {
					curr++;
					numSims = atoi(argv[curr]);
					
					// sanity checks
					if(numSims < 0) {
						cout << endl << "ERROR: Number of simulations cannot be set to " << numSims << endl;
						return 64;
					}
					
					cout << "Number of simulations set to " << numSims << endl;
				}
				
				// distance reductions
				else if(!strcmp(argv[curr], "-d")) {
					curr++;
					
					cout << "Thinning to be performed at distances of " << argv[curr] << " basepairs" << endl;
					
					chunk = strtok((char*) argv[curr], ",");
				
					// split to get list of distances
					while(chunk != NULL) {
						if(atoi(chunk) <= prevdist) {
							cout << "ERROR: Successive distances must be greater than the previous one; ";
							cout << atoi(chunk) << " is less than or equal to " << prevdist << endl;
							return 64;
						}
					
						distances.push_back(atoi(chunk));
						distnames.push_back((string) chunk);
						
						prevdist = atoi(chunk);
						chunk = strtok (NULL, ",");
					}
				}
				
				// SNP exclude list
				else if(!strcmp(argv[curr], "-m")) {
					curr++;
					
					snpListFileName = argv[curr];
				}
				
				// sample exclude list
				else if(!strcmp(argv[curr], "-s")) {
					curr++;
					
					sampleListFileName = argv[curr];
				}
				
				// full outlier detail output mode
				else if(!strcmp(argv[curr], "-f")) {
					fullOutput = true;
					
					cout << "Set to generate full outlier output" << endl;
				}
				
				// callrate cutoff
				else if(!strcmp(argv[curr], "-c")) {
					curr++;
					callrate = atof(argv[curr]);
					
					// sanity checks
					if(callrate < 0 || callrate > 1) {
						cout << endl << "ERROR: Call rate cannot be set to " << callrate << "; must be between 0 and 1" << endl;
						return 64;
					}
					
					cout << "Sample call rate set to " << callrate << endl;
				}
				
				else {
					cout << endl << "ERROR: Argument \"" << argv[curr] << "\" not recognised" << endl;
					return 64;
				}
			}
		}
	}
	
	else if(argc < 3) {
		cout << endl << "ERROR: Not enough arguments supplied\n";
		cout << endl << usage << endl;
		return 64;
	}
	
	

	// LOAD SNP DATA//
	/*--------------*/
	
	char * snpFileName = argv[curr];
	cout << "Reading SNP data from " << snpFileName << "\n";
	ifstream snpfile (snpFileName);
	
	// initialise some values
	int chunk_num = 0;
	vector<SNP> allSNPs;
	SNP s;
	int snpnumber = 0;
	string line;
	
	char * id_temp, * chr_temp, * misc_temp;
	
	map<string, int> snpNumbers;
	
	if(snpfile.is_open()) {
		while (!snpfile.eof()) {
			getline(snpfile,line);
			
			if(line.length() <= 1) break;
			
			chunk_num = 0;
			chunk = strtok((char*) line.c_str(), "\t ");
			
			// split the line
			while(chunk != NULL) {
				if(chunk_num == 0) {
					id_temp = chunk;
				}
				
				else if(chunk_num == 1) {
					chr_temp = chunk;
				}
				
				else if(chunk_num == 2) {
					s.pos = atoi(chunk);
				}
				
				// this is if we are dealing with a PLINK-style map file
				else if(chunk_num == 3) {
					
					// reassign the position variable
					s.pos = atoi(chunk);
					
					// switch the id and chr variables
					misc_temp = id_temp;
					id_temp = chr_temp;
					chr_temp = misc_temp;
					
// 					if(s.pos > maxPos[(string) chr_temp]) {
// 						maxPos[(string) chr_temp] = s.pos;
// 					}
				}
				
				chunk = strtok (NULL, "\t ");
				chunk_num++;
			}
			
			s.include = true;
			
			// finalise the values into the SNP object
			s.id = (string) id_temp;
			s.chr = (string) chr_temp;
			
			// add this SNP to the array
			allSNPs.push_back(s);
			
			// associate the SNP ID with its position in the allSNPs vector
			snpNumbers[s.id] = snpnumber;
			snpnumber++;
		}
		snpfile.close();
	}
	
	else {
		cout << "ERROR: Could not open SNP file " << snpFileName << endl;
		return 66;
	}
	
	// record the number of SNPs in the file
	int numsnps = snpnumber;
	
	cout << "Loaded info for " << snpnumber << " SNPs" << endl;
	
	
	
	
	// READ LIST OF EXCLUDED SNPS //
	/*----------------------------*/
	
	int numremoved = 0;
	
	if(strcmp(snpListFileName, "none")) {
		ifstream snpListFile(snpListFileName);
		
		if(snpListFile.is_open()) {
			while(!snpListFile.eof()) {
				getline(snpListFile, line);
				
				if(line.length() <= 1) break;
				
				chunk = strtok((char*) line.c_str(), "\t ");
				
				if(allSNPs[snpNumbers[(string) chunk]].include) {
					allSNPs[snpNumbers[(string) chunk]].include = false;
					numremoved++;
				}
			}
		}
		
		else {
			cout << "ERROR: Could not read from file " << snpListFileName << endl;
		}
		
		cout << "Removed " << numremoved << " SNPs listed in " << snpListFileName << endl;
	}
	
	// work out how many SNPs are remaining
	int snpsremaining = 0;
	
	for(int i=0; i<numsnps; i++) {
		if(allSNPs[i].include) {
			snpsremaining++;
		}
	}
	
	
	
	
	// READ LIST OF EXCLUDED SAMPLES //
	/*-------------------------------*/
	
	map<string, bool> excludeSamples;
	
	if(strcmp(sampleListFileName, "none")) {
		ifstream sampleListFile(sampleListFileName);
		
		if(sampleListFile.is_open()) {
			while(!sampleListFile.eof()) {
				getline(sampleListFile, line);
				
				if(line.length() <= 1) break;
				
				chunk = strtok((char*) line.c_str(), "\t ");
				
				excludeSamples[(string) chunk] = true;
			}
		}
		
		else {
			cout << "ERROR: Could not read from file " << sampleListFileName << endl;
		}
		
		cout << "Read list of " << excludeSamples.size() << " samples to be excluded from " << sampleListFileName << endl;
	}
	
	
	
	// LOAD GENOTYPE DATA//
	/*-------------------*/
	
	// create an array of maps for the genotype data
	map<string, int> * genoCounts;
	genoCounts = new map<string, int> [snpnumber];
	
// 	cout << "Created genoCounts" << endl;
	
	int * totalCounts = new int[numsnps];
// 	cout << "Created totalCounts" << endl;
	
	// create a similar array to temporarily hold data
	string * tempGeno = new string[numsnps];
// 	map<string, int> * tempGeno;
// 	tempGeno = new map<string, int> [snpnumber];
	
// 	cout << "Created tempGeno" << endl;
	
	// create an array of maps to keep track of observed genotypes
	map<string, bool> * seenGeno;
	seenGeno = new map<string, bool> [snpnumber];
// 	cout << "Created seenGeno" << endl;
	
	// clear the counts array so it's not full of random shite
	for(int i=0; i<numsnps; i++) {
		totalCounts[i] = 0;
	}
	
	map<string, bool> seenSamples;
	map<string, int> sampleNumbers;
	map<int, string> sampleOrder;
	map<int, int> gender;
	
	// open the genotype file
	char * genoFileName = argv[curr+1];
	cout << "Reading genotype data from " << genoFileName << endl;
	ifstream genofile (genoFileName);
	
	// initialise some values
	string value;
	string value_a;
	string value_b;
	string snp;
	string sample;
	
	int samplenumber = 0;
	int lineNumber = 0;
	int nulls;
	int crexc = 0;
	int numsamplesincluded = 0;
	
	if(genofile.is_open()) {
		while (!genofile.eof()) {
			LINE: getline(genofile,line);
			
			if(line.length() <= 1) break;
			
			chunk_num = 0;
			chunk = strtok((char*) line.c_str(), "\t ");
			
			snp = "";
			value = "";
			
			lineNumber++;
			
			nulls = 0;
			for(int i=0; i<numsnps; i++) {
				tempGeno[i] = "--";
			}
			
			// split the line
			while(chunk != NULL) {
				
				//cout << "Chunk " << chunk_num;
				
				// sample ID
				if(chunk_num == 0) {
					sample = (string) chunk;
					
					if(excludeSamples[sample]) goto LINE;
					if(seenSamples[sample]) {
						cout << "WARNING: Duplicate sample ID found (" << sample << "); skipping this instance" << endl;
						goto LINE;
					}
					
					seenSamples[sample] = true;
					
					sampleNumbers[sample] = samplenumber;
					sampleOrder[samplenumber] = sample;
					samplenumber++;
					//cout << "Sample " << samplenumber << endl;
				}
				
				// gender
// 				if(chunk_num == 5) {
// 					gender[samplenumber] = (int) chunk;
// 				}
				
				else if(chunk_num >= 6) {
					snpnumber = (chunk_num - 6)/2;
					
					// genotype a
					value_a = (string) chunk;
					
					// genotype b
					chunk = strtok (NULL, "\t ");
					chunk_num++;
					value_b = (string) chunk;
					
					value = value_a + value_b;
					
					
					//cout << snpnumber << " " << chunk_num << " " << value << endl;
					
					// check the snp number is in range
					if(snpnumber >= numsnps) {
						cout << "ERROR: Too many SNPs (" << snpnumber << ") on line " << lineNumber << " (should be " << numsnps << ")" << endl;
						return 64;
					}
					
					if(allSNPs[snpnumber].include) {
					
						// now check if it's null
						if((value != "--") && (value != "NN") && (value != "00")) {
							tempGeno[snpnumber] = value;
// 							genoCounts[snpnumber][value]++;
							totalCounts[snpnumber]++;
							
							seenGeno[snpnumber][value_a] = true;
							seenGeno[snpnumber][value_b] = true;
							
							if(seenGeno[snpnumber].size() > 2) {
								cout << "ERROR: Observed more than 2 alleles for SNP " << allSNPs[snpnumber].id << endl;
								return 64;
							}
						}
						
						else {
							nulls++;
						}
					}
				}
				
				chunk = strtok (NULL, "\t ");
				chunk_num++;
			}
			
			//cout << "Read line" << endl;
			
			// DEAL WITH NULLS
			if(1 - ((float) nulls / (float) snpsremaining) < callrate) {
				//cout << sample << " call rate = " << (1 - ((float) nulls / (float) snpsremaining)) << endl;
				//excludeSamples[sample] = true;
				crexc++;
				excludeSamples[sample] = true;
			}
			
			else {
				for(int i=0; i<numsnps; i++) {
		
					// add the genotypes from the temporary array to the counts
					if(tempGeno[i] != "--") {
						genoCounts[i][tempGeno[i]]++;
					}
				}
					
				numsamplesincluded++;
			}
		}
		
		genofile.close();
	}
	
	else {
		cout << "ERROR: Could not read from pedigree file " << genoFileName << endl;
		return 66;
	}
	
	cout << "Read counts from " << numsamplesincluded << " samples" << endl;
	
	if(crexc > 0) {
		cout << "Excluded " << crexc << " samples with call rate less than " << callrate << endl;
	}
	
	// check we still have some samples left!
	if(numsamplesincluded <= 0) {
		cout << "ERROR: No samples remaining for analysis" << endl;
		return 64;
	}
	
	
	// get the number of samples
	int numsamples = seenSamples.size();
	seenSamples.clear();
	
	// clear array of observed genotypes
	//seenGeno.clear();
	delete [] seenGeno;
	
	
	
	// OUTPUT GENOTYPE COUNTS
	/*---------------------*/
	
	cout << "Determining rare SNP classifications" << endl;
	
	// initialise some variables
	float ratio;
	
	// these are used for major/minor hom assignment
	int max = 0;
	int count;
	string major;
	string minor;
	string het;
	string prev;
	
	map<int, int> hetDist;
	map<int, int> homDist;
	
	// prepare a genotype file to write to
	ofstream genoDistFile;
	genoDistFile.open(((string) outStem + "_genotype.dist").c_str(), ios::out);
	
	// iterate through the SNPs
	for(int i=0; i<numsnps; i++) {
		
		// reset the genotype assignments
		major = "??";
		minor = "??";
		het = "??";
		prev = "??";
		max = 0;
	
		// make sure that counts for this SNP have been observed
		if((genoCounts[i].size() >= 1) && (allSNPs[i].include)) {
			
			// make genotype assignments
			for(map<string, int>::iterator iter = genoCounts[i].begin(); iter != genoCounts[i].end(); iter++) {
			
				// copy values for ease of use
				value = iter->first;
				count = iter->second;
				
				// assign het status if genotype is het
				if(isHet(value)) {
					het = value;
				}
				
				// otherwise determine whether this is the major or minor hom
				else {
					minor = value;
					
					if(count > max) {
						major = value;
						minor = prev;
						max = count;
						prev = value;
					}
				}
			}
			
			if(minor == major) {
				minor = "??";
			}
			
			
// 			// assess rare hom status
// 			ratio = (float) genoCounts[i][het] / (float) totalCounts[i];
// 			
// 			if((minor != "??") && (genoCounts[i][minor] >= genoCounts[i][het]) && (ratio <= homFrac)) {
// 				allSNPs[i].rareHom = minor;
// 				homDist[genoCounts[i][minor]]++;
// 			}
// 			else {
// 				allSNPs[i].rareHom = "-";
// 			}
			
			
			
			
			
			
			
			// assess rare hom status
			if(homCount == 99999) {
				ratio = (float) genoCounts[i][het] / (float) totalCounts[i];
				
				if((minor != "??") && (genoCounts[i][minor] > 0) && (genoCounts[i][minor] >= genoCounts[i][het]) && (ratio <= homFrac)) {
					allSNPs[i].rareHom = minor;
					homDist[genoCounts[i][minor]]++;
				}
				else {
					allSNPs[i].rareHom = "-";
				}
			}
			
			// use count instead of fraction if provided
			else {
				if((minor != "??") && (genoCounts[i][minor] > 0) && (genoCounts[i][minor] >= genoCounts[i][het]) && (genoCounts[i][het] <= homCount)) {
					allSNPs[i].rareHom = minor;
					homDist[genoCounts[i][minor]]++;
				}
				else {
					allSNPs[i].rareHom = "-";
				}
			}
			
			
			
			
			
			
// 			// assess rare het status
// 			
// 			if((het != "??") && (ratio <= hetFrac) && (genoCounts[i][minor] == 0)) {
// 				allSNPs[i].rareHet = het;
// 				hetDist[genoCounts[i][het]]++;
// 			}
// 			else {
// 				allSNPs[i].rareHet = "-";
// 			}
			
			
			// assess rare het status
			if(hetCount == 99999) {
				if((het != "??") && (genoCounts[i][het] > 0) && (ratio <= hetFrac) && (ratio > lHetFrac) && (genoCounts[i][minor] <= resHom) && (ratio > 0)) {
					allSNPs[i].rareHet = het;
					hetDist[genoCounts[i][het]]++;
				}
				else {
					allSNPs[i].rareHet = "-";
				}
			}
			
			// use count instead of fraction if provided
			else {
				if((het != "??") && (genoCounts[i][het] > 0) && (genoCounts[i][het] <= hetCount) && (genoCounts[i][minor] <= resHom)) {
					allSNPs[i].rareHet = het;
					hetDist[genoCounts[i][het]]++;
				}
				else {
					allSNPs[i].rareHet = "-";
				}
			}
			
			
			
			
			
			genoDistFile << allSNPs[i].id; // output the SNP ID
			genoDistFile << "\t" << genoCounts[i][minor] << "\t" << genoCounts[i][het] << "\t" << genoCounts[i][major]; // output genotype counts
			genoDistFile << "\t" << minor << "\t" << het << "\t" << major; // output genotype assignments
			genoDistFile << "\t" << allSNPs[i].rareHet << "\t" << allSNPs[i].rareHom;
			genoDistFile << endl; // end the line
			
			
			// free up some memory by clearing this map
			genoCounts[i].clear();
		}
	}
	
	delete [] genoCounts;
	
	genoDistFile.close();
	
	cout << "Wrote genotype distribution to " << ((string) outStem + "_genotype.dist") << endl;
	
	
// 	// WRITE SNP DISTRIBUTION //
// 	/*------------------------*/
// 	
// // 	if((homDist.size() > 0) || (hetDist.size() > 0)) {
// 		ofstream snpDistFile;
// 		snpDistFile.open(((string) outStem + "_snp.dist").c_str(), ios::out);
// 		
// // 		if(hetDist.size() > 0) {
// 		
// 			snpDistFile << "Het counts: " << endl;
// 			
// 			for(map<int, int, intCmp>::iterator iter = hetDist.begin(); iter != hetDist.end(); iter++) {
// 				snpDistFile << iter->first << "\t" << iter->second << endl;
// 			}
// // 		}
// 		
// // 		if(homDist.size() > 0) {
// 		
// 			snpDistFile << endl << "Hom counts: " << endl;
// 			
// 			for(map<int, int, intCmp>::iterator iter = homDist.begin(); iter != homDist.end(); iter++) {
// 				snpDistFile << iter->first << "\t" << iter->second << endl;
// 			}
// // 		}
// 		
// 		snpDistFile.close();
// // 	}
// // 	
// // 	else {
// // 	 	cout << "ERROR: No rare heterozygote or homozygote SNPs found" << endl;
// // 	 	return 0;
// // 	}
	
	
	// RESCAN FILE FOR COUNTS //
	/*------------------------*/
	
	map<int, bool> * hetCounts;
	hetCounts = new map<int, bool> [numsamples];
	
	map<int, bool> * homCounts;
	homCounts = new map<int, bool> [numsamples];
	
	ifstream genofilea (genoFileName);
	
// 	int region_size = 5000000;
// 	int region;
	string chr;
	int pos;
// 	string region_name;
// 	map<string, int> region_counts;
// 	float cluster_scores[numsamples];
// 	int empties[numsamples];
// 	int lows[numsamples];
// 	int nonecount, lowcount, low, mid, high, total_counts;
	
	cout << "Re-reading genotype data from " << genoFileName << endl;
	
	float currperc = 0;
	
	
	if(genofilea.is_open()) {
		while (!genofilea.eof()) {
			LINEB: getline(genofilea,line);
			
			if(line.length() <= 1) break;
			
			chunk_num = 0;
			chunk = strtok((char*) line.c_str(), "\t ");
			
			snp = "";
			value = "";
			
			
			// split the line
			while(chunk != NULL) {
				if(chunk_num == 0) {
					sample = (string) chunk;
					
					if(excludeSamples[sample]) goto LINEB;
					if(seenSamples[sample]) goto LINEB;
					
					seenSamples[sample] = true;
					
					samplenumber = sampleNumbers[sample];
					
					if((float) samplenumber / (float) numsamplesincluded > currperc) {
						cout << "..." << (100 * currperc) << "%" << endl;
						currperc += 0.1;
					}
				}
				
				else if(chunk_num >= 6) {
					snpnumber = (chunk_num - 6) / 2;
					
					// genotype a
					value_a = (string) chunk;
					
					// genotype b
					chunk = strtok (NULL, "\t ");
					chunk_num++;
					value_b = (string) chunk;
					
					value = value_a + value_b;
					
					if(allSNPs[snpnumber].include) {
					
						if(allSNPs[snpnumber].rareHet == value) {
							hetCounts[samplenumber][snpnumber] = true;
							
// 							chr = allSNPs[snpnumber].chr;
// 							pos = allSNPs[snpnumber].pos;
// 							
// 							region = (pos / region_size);
// 							
// 							stringstream tempstream;
// 							tempstream << region;
// 							
// 							region_name = tempstream.str();
// 							region_name = chr + " " + region_name;
// 							
// 							//cout << "Region " << region_name << " " << pos << endl;
// 							
// 							region_counts[region_name]++;
						}
						
						if(allSNPs[snpnumber].rareHom == value) {
							homCounts[samplenumber][snpnumber] = true;
						}
					}
				}
				
				chunk = strtok (NULL, "\t ");
				chunk_num++;
			}
			
// 			nonecount = 0;
// 			lowcount = 0;
// 			total_counts = 0;
// 			low = 0;
// 			mid = 0;
// 			high = 0;
// 			
// 			// iterate through the "blank" regions
// 			for(map<string, int, strCmp>::iterator chriter = maxPos.begin(); chriter != maxPos.end(); chriter++) {
// 				pos = 1;
// 				
// 				while(pos < chriter->second) {
// 					region = (pos / region_size);
// 					
// 					stringstream tempstream;
// 					tempstream << region;
// 					
// 					region_name = tempstream.str();
// 					region_name = chriter->first + " " + region_name;
// 					
// 					if(region_counts[region_name] < 1) {
// 						//region_counts[region_name] = 0;
// 						nonecount++;
// 					}
// 					
// 					total_counts++;
// 					
// 					//cout << samplenumber << "\t" << chriter->first << "\t" << chriter->second << "\t" << pos << endl;
// 				
// 					pos += region_size;
// 				}
// 			}
// 			
// 			
// 			for(map<string, int, strCmp>::iterator iter2 = region_counts.begin(); iter2 != region_counts.end(); iter2++) {
// 				if((region_counts[iter2->first] >= 1) && (region_counts[iter2->first] <= 2)) {
// 					low += region_counts[iter2->first];
// 					lowcount++;
// 				}
// 				
// 				else if(region_counts[iter2->first] <= 6) {
// 					mid += region_counts[iter2->first];
// 				}
// 				
// 				else {
// 					high += region_counts[iter2->first];
// 				}
// 			}
// 			
// 			empties[samplenumber] = nonecount;
// 			lows[samplenumber] = lowcount;
// 			
// 			if(low + mid + high > 0) {
// 				cluster_scores[samplenumber] = 100 * ((float) high / (float) (low + mid + high));
// 			}
// 			
// 			else {
// 				cluster_scores[samplenumber] = 0;
// 			}
// 			
// 			region_counts.clear();
		}
		
		genofile.close();
		
		cout << "Finished re-reading data" << endl;
	}
	
	
	
	
	// WRITE SAMPLE DISTRIBUTION //
	/*---------------------------*/
	
	// stuff for simulations
	cout << "Running simulations for rare het counts" << endl;
	map <int, int> hetSim = runSims(&hetDist, numsamples, numSims);
	cout << "Running simulations for rare hom counts" << endl;
	map <int, int> homSim = runSims(&homDist, numsamples, numSims);
	
	float hetp, homp;
	
	ofstream sampleDistFile;
	sampleDistFile.open(((string) outStem + "_sample.dist").c_str(), ios::out);
	
	ofstream fullFile;
	if(fullOutput) {
		fullFile.open(((string) outStem + "_full.sample.dist").c_str(), ios::out);
	}
	
	for(int i=0; i<numsamples; i++) {
		if(hetSim[hetCounts[i].size()]) {
			hetp = (float) hetSim[hetCounts[i].size()] / (float) numSims;
			if(hetp > 1) hetp = 1;
		}
		
		else {
			hetp = 0;
		}
		
		if(homSim[homCounts[i].size()]) {
			homp = (float) homSim[homCounts[i].size()] / (float) numSims;
			if(homp > 1) homp = 1;
		}
		
		else {
			homp = 0;
		}
	
		sampleDistFile << sampleOrder[i] << "\t" << hetCounts[i].size() << "\t" << hetp;
		sampleDistFile << "\t" << homCounts[i].size() << "\t" << homp << endl;
// 		sampleDistFile << "\t" << cluster_scores[i] << "\t" << empties[i] << "\t" << lows[i] << "\t" << total_counts << endl;
		
		
		// do full output
		if(fullOutput) {
			for(map<int, bool, intCmp>::iterator iter = hetCounts[i].begin(); iter != hetCounts[i].end(); iter++) {
				fullFile << sampleOrder[i] << "\t" << allSNPs[iter->first].id << "\tHET" << endl;
			}
			for(map<int, bool, intCmp>::iterator iter = homCounts[i].begin(); iter != homCounts[i].end(); iter++) {
				fullFile << sampleOrder[i] << "\t" << allSNPs[iter->first].id << "\tHOM" << endl;
			}
		}
	}
	
	sampleDistFile.close();
	cout << "Wrote sample distribution to " << ((string) outStem + "_sample.dist") << endl;
	
	if(fullOutput) {
		fullFile.close();
		cout << "Wrote full sample distribution to " << ((string) outStem + "_full.sample.dist") << endl;
	}
	
	
	
	// DO DISTANCE REDUCTION //
	/*-----------------------*/
	
	if(distances.size() > 0) {
		
		string prev_chr;
		string prev_id;
		int prev_pos;
		int dist;
	
		ofstream sampleRedDistFile;
		string filename;
		string fullfilename;
		
		//int before, after;
		
		map<int, bool> remove;
		
		cout << "Performing distance reductions" << endl;
		
		for(int d=0; d<distances.size(); d++) {
			dist = distances[d];
		
			for(int i=0; i<numsamples; i++) {
				if((hetCounts[i].size() == 0) && (homCounts[i].size() == 0)) continue;
				
				// clear the array of removed SNPs
				remove.clear();
				
				// clear variables
				prev_pos = 0;
				prev_chr = "";
				
				// do the hets
				for(map<int, bool, intCmp>::iterator iter = hetCounts[i].begin(); iter != hetCounts[i].end(); iter++) {
					if(remove[iter->first]) continue;
					
					pos = allSNPs[iter->first].pos;
					chr = allSNPs[iter->first].chr;
					
					if((chr == prev_chr) && ((pos - prev_pos) < dist)) {
						//cout << sampleOrder[i] << " Eliminating " << allSNPs[iter->first].id << " (" << prev_id << ")" << "\t" << chr << "\t" << pos << "\t" << prev_pos << "\t" << dist << endl;
						
						//hetCounts[i].erase(iter);
						
						// flag this SNP for removal
						remove[iter->first] = true;
					}
					else {
						prev_pos = pos;
						prev_chr = chr;
						prev_id = allSNPs[iter->first].id;
					}
				}
				
				// do the actual removing
				for(map<int, bool, intCmp>::iterator iter = hetCounts[i].begin(); iter != hetCounts[i].end(); iter++) {
					if(remove[iter->first]) {
						hetCounts[i].erase(iter);
						//cout << sampleOrder[i] << " Eliminating " << allSNPs[iter->first].id << endl;
					}
				}
				
				
			
				// clear the array of removed SNPs
				remove.clear();
				
				// clear variables
				prev_pos = 0;
				prev_chr = "";
				
				// do the homs
				for(map<int, bool, intCmp>::iterator iter = homCounts[i].begin(); iter != homCounts[i].end(); iter++) {
					if(remove[iter->first]) continue;
					
					pos = allSNPs[iter->first].pos;
					chr = allSNPs[iter->first].chr;
					
					if((chr == prev_chr) && ((pos - prev_pos) < dist)) {
						//homCounts[i].erase(iter);
						
						// flag this SNP for removal
						remove[iter->first] = true;
					}
					else {
						prev_pos = pos;
						prev_chr = chr;
					}
				}
				
				// do the actual removing
				for(map<int, bool, intCmp>::iterator iter = homCounts[i].begin(); iter != homCounts[i].end(); iter++) {
					if(remove[iter->first]) homCounts[i].erase(iter);
				}
			}
			
			filename = "";
			filename = "_" + distnames[d] + ".sample.dist";
			fullfilename = "_" + distnames[d] + ".full.sample.dist";
			
			sampleRedDistFile.open(((string) outStem + filename).c_str(), ios::out);
			
			if(fullOutput) fullFile.open(((string) outStem + fullfilename).c_str(), ios::out);
			
			
			for(int i=0; i<numsamples; i++) {
				if(hetSim[hetCounts[i].size()]) {
					hetp = (float) hetSim[hetCounts[i].size()] / (float) numSims;
					if(hetp > 1) hetp = 1;
				}
				
				else {
					hetp = 0;
				}
				
				if(homSim[homCounts[i].size()]) {
					homp = (float) homSim[homCounts[i].size()] / (float) numSims;
					if(homp > 1) homp = 1;
				}
				
				else {
					homp = 0;
				}
			
				sampleRedDistFile << sampleOrder[i] << "\t" << hetCounts[i].size() << "\t" << hetp;
				sampleRedDistFile << "\t" << homCounts[i].size() << "\t" << homp << endl;
				
				// do full output
				if(fullOutput) {
					for(map<int, bool, intCmp>::iterator iter = hetCounts[i].begin(); iter != hetCounts[i].end(); iter++) {
						fullFile << sampleOrder[i] << "\t" << allSNPs[iter->first].id << "\tHET" << endl;
					}
					for(map<int, bool, intCmp>::iterator iter = homCounts[i].begin(); iter != homCounts[i].end(); iter++) {
						fullFile << sampleOrder[i] << "\t" << allSNPs[iter->first].id << "\tHOM" << endl;
					}
				}
			}
			
			cout << "Wrote reduced sample distribution to " << ((string) outStem + filename) << endl;
	
			if(fullOutput) {
				fullFile.close();
				cout << "Wrote reduced full sample distribution to " << ((string) outStem + fullfilename) << endl;
			}
		}
	}
	
	time(&rawtime);
	cout << endl << "Completed succesfully" << endl << asctime(localtime(&rawtime)) << endl;
	
		
	return 0;
} // end of main program




/*---------------------------------*/
/* SUBROUTINE TO ASSESS HET STATUS */
/*---------------------------------*/

bool isHet(string geno) {
	if(geno.substr(0,1) == geno.substr(1,1)) {
		return false;
	}
	
	else {
		return true;
	}
}




/*-------------------------------*/
/* SUBROUTINE TO RUN SIMULATIONS */
/*-------------------------------*/

map<int, int> runSims(map<int, int> * dist, int numSamples, int numSims) {
	int * samples;
	samples = new int [numSamples];
	
	bool * already;
	already = new bool [numSamples];
	
	map <int, int> observed;
	map <int, int> cumulative;
	
	int count, snp, samplenumber, min, max;
	
	// initialise the random number generator
	int seed = time(0);
	TRandomMotherOfAll rg(seed);
	
	float currperc = 0;
	
	for(int sim=0; sim < numSims; sim++) {
	
		if((float) sim / (float) numSims > currperc) {
			cout << "..." << (100 * currperc) << "%" << endl;
			currperc += 0.1;
		}
		
		// clear the samples array
		for(int i=0; i<numSamples; i++) {
			samples[i] = 0;
		}
		
		// clear the observed map
		observed.clear();
		
		// iterate through the SNP distribution
		for(map<int, int, intCmp>::iterator iter = dist->begin(); iter != dist->end(); iter++) {
			
			// value is the number of SNPs observed to contribute a particular number of counts
			snp = iter->second;
			
			while(snp--) {
			
				// key is the number of counts
				count = iter->first;
				
				// clear the array of already done samples
				for(int i=0; i<numSamples; i++) {
					already[i] = false;
				}
				
				// drop counts into random samples
				while(count--) {
					// choose a random sample
					samplenumber = rg.IRandom(0,numSamples-1);
					
					// make sure this SNP hasn't contributed a count to this sample already
					while(already[samplenumber]) {
						samplenumber = rg.IRandom(0,numSamples-1);
					}
					
					samples[samplenumber]++;
					
					// record this sample as already having a count from this SNP
					already[samplenumber] = true;
				}
			}
		}
		
		min = 100000000;
		max = 0;
		
		// assess the output for this run
		for(int i=0; i<numSamples; i++) {
			observed[samples[i]]++;
			
			if(samples[i] < min) min = samples[i];
			if(samples[i] > max) max = samples[i];
		}
		
		// add the observed counts in this run to the summary
		//cout << "min: " << min << " max: " << max << endl;
		
		for(int i=min; i<=max; i++) { //map<int, int, intCmp>::iterator iter = observed.begin(); iter != observed.end(); iter++) {
			
			//cout << observed[i] << " samples with " << i << " rare hets " << endl;
		
			// create an iterator that goes from this key to the end; generates cumulative counts
			for(int j=i; j<=max; j++) { //map<int, int, intCmp>::iterator itera = iter; itera != observed.end(); itera++) {
			
				cumulative[i] += observed[j];
				
				//cout << "\t" << i << " gets " << observed[j] << " more from " << j << ", making " << cumulative[i] << endl;
			}
		}
	}
	
	// some cleanup
	delete [] samples;
	delete [] already;
	
	cout << "Finished simulations" << endl;
	
	return cumulative;
}
