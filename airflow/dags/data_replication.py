from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
import psycopg2
import mysql.connector

def task_function():
    #print(psycopg2.__version__)
    #print(mysql.connector.version.VERSION_TEXT)
    tables = ['users', 'productcategories', 'products', 'orders', 'order_details']

    try:
        connection_src = psycopg2.connect(database = "postgres_db",
                        host =     "host.docker.internal",
                        user =     "student",
                        password = "student",
                        port =     "5430")
    
    except:
        print('No source connection')
        return None
    
    try:
        connection_trg = mysql.connector.connect(
                        database=  "mysql_db",
                        host =     "host.docker.internal",
                        user =     "student",
                        password = "student",
                        port =     "3305")
    
    except:
        print('No target connection')
        return None   

    # Отключение автокоммита
    connection_src.autocommit = False

    for tbl in tables:

        print('Starting to migrate...', tbl)
    
        # assuming that given connection is valid and established with appropriate rights and user credentials
        
        # Создание курсора    
        try:
            cursor_src = connection_src.cursor()
        except:
            print('Could not open source cursor')
            return None   

         # Создание курсора    
        try:
            cursor_trg = connection_trg.cursor()
        except:
            print('Could not open target cursor')
            return None  

        sql_query_select =  """ 
                            select * from {}
                            """
        sql_query_truncate =  """ 
                            truncate table {}
                            """
        sql_query_insert = """ 
                            insert into {}({}) values ({})
                            """
        try:
            print("truncating table...", tbl)
            cursor_trg.execute(
                        sql_query_truncate.format(tbl)
                        )
        except:
            print('Could not truncate target table')
            return None  
                    
        try:
            print('Selecting ...',  sql_query_select.format(tbl))
            cursor_src.execute(
                        sql_query_select.format(tbl)
                        )
            columns = [x[0] for x in cursor_src.description]
            columns_str = ','.join(columns)
            cols_place_holder = []
            for i in range(len(columns)):
                cols_place_holder.append('%s')
            cols_place_holder_str = ','.join(cols_place_holder)
            
            for row in cursor_src:
                try:
                    print('Trying to insert...')
                    cursor_trg.execute(sql_query_insert.format(tbl, columns_str, cols_place_holder_str), row)
                except:
                    print('Could not insert into target table')
                    return None  
                  
            connection_trg.commit()
            cursor_trg.close()
            

            cursor_src.close()

        except:
            print('Could not read from cursor')
            cursor_src.close()
            return None   

        connection_src.commit()
        cursor_src.close()

default_args  = {
    'owner': 'airflow',
    'retries':5,
    'retry_delay':timedelta(minutes=2)
    }

with DAG(
    dag_id = 'python_project_dag_migrate',
    default_args = default_args,
    description = 'data migration from pg to mysql',
    start_date = datetime(2025,1,10),
    schedule_interval = '@daily'
) as dag:
    task1 = PythonOperator(
        task_id = 'data_migration_task',
        python_callable = task_function
    )

    task1
    