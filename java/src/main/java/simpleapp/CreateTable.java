package simpleapp;

import joptsimple.*;
import org.apache.log4j.Logger;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintWriter;

public class CreateTable {
    static Logger logger = Logger.getLogger(CreateTable.class);

    static public void main(String[] argc) {
        logger.info("--------------- simpleapp.CreateTable start...");
        Parameters p = new Parameters();
        p.parse(argc);
        SparkSession.Builder builder = SparkSession.builder();
        builder.enableHiveSupport();
        SparkSession spark = builder.getOrCreate();
        Dataset<Row> df = spark.read().option("header", true).option("inferSchema", true).option("delimiter", ",").csv(p.getSrc());
        df.createOrReplaceTempView("_src_");
        df.show();
        spark.sql(String.format("CREATE DATABASE IF NOT EXISTS %s", p.getDatabase()));
        spark.sql(String.format("DROP TABLE IF EXISTS %s.%s", p.getDatabase(), p.getTable()));
        spark.sql(String.format("CREATE TABLE IF NOT EXISTS %s.%s USING PARQUET LOCATION 's3a://%s/%s/%s' AS %s", p.getDatabase(), p.getTable(), p.getBucket(), p.getDatamartFolder(), p.getTable(), p.getSelect()));
        spark.sql(String.format("SHOW TABLES FROM %s", p.getDatabase())).show();
        spark.sql(String.format("DESCRIBE TABLE %s.%s", p.getDatabase(), p.getTable())).show();
        spark.sql(String.format("SELECT COUNT(*) FROM %s.%s", p.getDatabase(), p.getTable())).show();
        spark.stop();
        logger.info("--------------- EXITING........");
        System.exit(0);
    }

    static private class Parameters {
        private final OptionParser parser;
        private String src;
        private String bucket;
        private String database;
        private String table;
        private String datamartFolder;
        private String select;

        public Parameters() {
            this.parser = new OptionParser();
            parser.formatHelpWith(new BuiltinHelpFormatter(120, 2));
        }

        public void parse(String[] argc) {
            try {
                OptionSpec<String> SRC_OPT = parser.accepts("src", "S3 path of source csv file").withRequiredArg().ofType(String.class).required();
                OptionSpec<String> BUCKET_OPT = parser.accepts("bucket", "S3 destination bucket").withRequiredArg().ofType(String.class).required();
                OptionSpec<String> DATABASE_OPT = parser.accepts("database", "Destination hive database").withRequiredArg().ofType(String.class).required();
                OptionSpec<String> TABLE_OPT = parser.accepts("table", "Destination hive table").withRequiredArg().ofType(String.class).required();
                OptionSpec<String> DATAMART_FOLDER_OPT = parser.accepts("datamartFolder", "Datamart S3 folder").withRequiredArg().ofType(String.class).required();
                OptionSpec<String> SELECT_OPT = parser.accepts("select", "The select part of CTAS").withRequiredArg().ofType(String.class).required();
                OptionSet result = this.parser.parse(argc);
                this.src = result.valueOf(SRC_OPT);
                this.bucket = result.valueOf(BUCKET_OPT);
                this.database = result.valueOf(DATABASE_OPT);
                this.table = result.valueOf(TABLE_OPT);
                this.datamartFolder = result.valueOf(DATAMART_FOLDER_OPT);
                this.select = result.valueOf(SELECT_OPT);
            } catch (OptionException e) {
                System.out.println(usage(e.getMessage()));
                System.exit(1);
            }
        }

        public String getSrc() {
            return src;
        }

        public String getBucket() {
            return bucket;
        }

        public String getDatabase() {
            return database;
        }

        public String getTable() {
            return table;
        }

        public String getDatamartFolder() {
            return datamartFolder;
        }

        public String getSelect() {
            return select;
        }

        protected String usage(String err) {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            PrintWriter pw = new PrintWriter(baos);
            if (err != null) {
                pw.print(String.format("\n\n * * * * * ERROR: %s\n\n", err));
            }
            try {
                parser.printHelpOn(pw);
            } catch (IOException e) {
                // Skip
            }
            pw.flush();
            pw.close();
            return baos.toString();
        }
    }
}