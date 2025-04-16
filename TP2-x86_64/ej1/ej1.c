#include "ej1.h"
#include <stdlib.h>
#include <string.h> 

string_proc_list* string_proc_list_create(void){
    string_proc_list* new_list = (string_proc_list*)malloc(sizeof(string_proc_list));
    if (new_list == NULL) {
        return NULL;
    }
    new_list->first = NULL;
    new_list->last = NULL;
    return new_list;
}

string_proc_node* string_proc_node_create(uint8_t type, char* hash){
    string_proc_node* new_node = (string_proc_node*)malloc(sizeof(string_proc_node));
    if (new_node == NULL) {
        return NULL;
    }
    new_node->next = NULL;
    new_node->previous = NULL;
    new_node->type = type;
    new_node->hash = hash; 
    return new_node;
}

void string_proc_list_add_node(string_proc_list* list, uint8_t type, char* hash){
    if (list == NULL) {
        return; 
    }
	string_proc_node* new_node = string_proc_node_create(type, hash);
    if (new_node == NULL) {
        return;
    }

    if (list->last == NULL) {
        list->first = new_node;
        list->last = new_node;
    } else {
        list->last->next = new_node;   
        new_node->previous = list->last; 
        list->last = new_node;     
    }
}

char* string_proc_list_concat(string_proc_list* list, uint8_t type , char* hash){
    if (list == NULL || hash == NULL) {
        return NULL;
    }

    char* result_hash = str_concat("", hash);
    if (result_hash == NULL){
         return NULL; 
    }


    string_proc_node* current_node = list->first;
    while (current_node != NULL) {
        if (current_node->type == type) {
            char* temp_hash = str_concat(result_hash, current_node->hash);
            if (temp_hash == NULL) {
                 free(result_hash);
                 return NULL;
            }
            free(result_hash);
            result_hash = temp_hash;
        }
        current_node = current_node->next;
    }

    return result_hash;
}

/** AUX FUNCTIONS **/

void string_proc_list_destroy(string_proc_list* list){

	/* borro los nodos: */
	string_proc_node* current_node	= list->first;
	string_proc_node* next_node		= NULL;
	while(current_node != NULL){
		next_node = current_node->next;
		string_proc_node_destroy(current_node);
		current_node	= next_node;
	}
	/*borro la lista:*/
	list->first = NULL;
	list->last  = NULL;
	free(list);
}
void string_proc_node_destroy(string_proc_node* node){
	node->next      = NULL;
	node->previous	= NULL;
	node->hash		= NULL;
	node->type      = 0;			
	free(node);
}
char* str_concat(char* a, char* b) {
	int len1 = strlen(a);
    int len2 = strlen(b);
	int totalLength = len1 + len2;
    char *result = (char *)malloc(totalLength + 1); 
    strcpy(result, a);
    strcat(result, b);
    return result;  
}
void string_proc_list_print(string_proc_list* list, FILE* file){
        uint32_t length = 0;
        string_proc_node* current_node  = list->first;
        while(current_node != NULL){
                length++;
                current_node = current_node->next;
        }
        fprintf( file, "List length: %d\n", length );
		current_node    = list->first;
        while(current_node != NULL){
                fprintf(file, "\tnode hash: %s | type: %d\n", current_node->hash, current_node->type);
                current_node = current_node->next;
        }
}