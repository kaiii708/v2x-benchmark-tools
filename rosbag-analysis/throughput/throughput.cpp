#include <iostream>
#include <sqlite3.h>
#include <fstream>
#include <sstream>
#include <string.h>
#include <cmath>
using namespace std;

#define MAX_TOPIC_COUNT 10
#define MAX_SQL_COMMAND 128
struct Bag{
    int topic_id;
    long int min_timestamp;
    long int max_timestamp;
    bool isOccupied=false;
    double throughput=0;
};

struct Opt{
    string db_path;
    long int window_secs;
    int topic_count=0;
    Bag bags[MAX_TOPIC_COUNT];
};

Opt opt;
long int discarded_window=10000000;
// struct CallbackData{
//     Opt opt;
//     string command;
//     int topid_id;
// }; ///TODO///

// static int callback(void *data, int argc, char **argv, char **azColName){
//    int i;
// //    fprintf(stderr, "%s: ", (const char*)data);
//    for(i=0; i<argc; i++){
//         if(!strcmp(azColName[i],"topic_id") && !strcmp(argv[i],"2")){
//             // cout<<azColName[i];
//             // printf("%s = %s\n", azColName[i+1], argv[i+1] ? argv[i+1] : "NULL");
//             if(!strcmp(argv[i+1],"1691559202056446206")){
//                 cout<<strlen(argv[i+2]);
//             }
//         }
//     //   printf("%s = %s\n", azColName[i], argv[i] ? argv[i] : "NULL");
//    }
// //    printf("\n");
//    return 0;
// }

static int read_max_topic_id(void *NotUsed, int argc, char **argv, char **azColName){
    opt.topic_count=stoi(argv[0]);  ///TODO///
    
    return 0;
}

static int read_min_timestamp(void *para, int argc, char **argv, char **azColName){
    int topid_id=*((int*)para);
    opt.bags[topid_id].min_timestamp=stol(argv[0]);
    return 0;
}

static int read_max_timestamp(void *para, int argc, char **argv, char **azColName){
    int topid_id=*((int*)para);
    
    opt.bags[topid_id].max_timestamp=stol(argv[0]);
    return 0;
}

static int accumulate_windowsize_throughput(void *para, int argc, char **argv, char **azColName){
    int topic_id=*((int*)para);
    cout<<"The average thoughput of this window which topid_id="<<topic_id<<": "<<argv[0]<<" bytes."<<endl;
    opt.bags[topic_id].throughput+=atof(argv[0])*8;
    return 0;
}

int main() {
    //read config
    ifstream conf("./rosbag.conf");
    string line;
    if (conf.is_open() == false)
    {
      return false;
    }
    
    while(getline(conf,line)){
        istringstream sline(line);
        string key;
        if(getline(sline,key,'=')){
            string value;
            if(getline(sline,value)){
                if (key == "db_path"){
                    opt.db_path = value;
                }
                else if (key == "window_secs"){
                    opt.window_secs=stol(value);
                }
            }
        }

    }


    int rc;
    sqlite3 *db = NULL;
    char *zErrMsg = 0;

    rc = sqlite3_open(opt.db_path.c_str(), &db);

    if(rc){
        fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
        exit(0);
    }
    else{
        fprintf(stdout, "Opened database successfully\n");
    }
    
    int min_timestamp=-1;
    char *sql=(char *) malloc(sizeof(char) * MAX_SQL_COMMAND);
    
    strcpy(sql,"SELECT MAX(topic_id) FROM messages");
    
    rc = sqlite3_exec(db, sql, read_max_topic_id, 0, &zErrMsg);
    // free(sql);
    if( rc != SQLITE_OK ){
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        sqlite3_free(zErrMsg);
    }else{
        fprintf(stdout, "Operation done successfully\n");
    }
    printf("hi i am trying,%d\n",opt.topic_count);
    for(int i = 1; i<=opt.topic_count; i++){
        strcpy(sql,"SELECT MIN(timestamp) FROM messages WHERE topic_id=");
        stringstream strs;
        strs << i;
        string str_topic_id = strs.str();
        strs.clear();
        char const * topic_id = str_topic_id.c_str();
        strcat(sql,topic_id);
        
        rc = sqlite3_exec(db, sql, read_min_timestamp, (void *)&i, &zErrMsg);
        if( rc != SQLITE_OK ){
            fprintf(stderr, "SQL error: %s\n", zErrMsg);
            sqlite3_free(zErrMsg);
        }else{
            fprintf(stdout, "Operation done successfully\n");
        }

        strcpy(sql,"SELECT MAX(timestamp) FROM messages WHERE topic_id=");
        
        strcat(sql,topic_id);
        
        rc = sqlite3_exec(db, sql, read_max_timestamp, (void *)&i, &zErrMsg);
        if( rc != SQLITE_OK ){
            fprintf(stderr, "SQL error: %s\n", zErrMsg);
            sqlite3_free(zErrMsg);
        }else{
            fprintf(stdout, "Operation done successfully\n");
        }
        bool end_loop = false;
        int window_count=0;
        for(long int window_start=opt.bags[i].min_timestamp+=discarded_window;;window_start+=opt.window_secs){
            ////TODO///
            
            long int window_end=window_start+opt.window_secs-1;
            if(window_end>=opt.bags[i].max_timestamp-discarded_window){
                window_end=opt.bags[i].max_timestamp-discarded_window;
                end_loop=true;
            }
            window_count+=1;
            
            memset(sql,'\0',sizeof(sql));
            sprintf(sql,"SELECT SUM(length(data))/%ld FROM messages WHERE topic_id=%d AND %ld<=timestamp<=%ld",opt.window_secs,i,window_start,window_end);
            
            ///TODO:can string be reassigned?///
            
            rc = sqlite3_exec(db, sql, accumulate_windowsize_throughput, (void *)&i, &zErrMsg);
            if( rc != SQLITE_OK ){
                fprintf(stderr, "SQL error: %s\n", zErrMsg);
                sqlite3_free(zErrMsg);
            }else{
                fprintf(stdout, "Operation done successfully\n");
            }

            if(end_loop == true){
                break;
            }
        }
        opt.bags[i].throughput/=window_count;
    }
    for(int i = 1; i<=opt.topic_count; i++){
        cout<<"The bag "<<i<<" average throughput in window size "<<opt.window_secs<<": "<<opt.bags[i].throughput<<" bits"<<endl;
    }
    free(sql);
    sqlite3_close(db);
    return 0;
}