package za.org.samac.harvest;

import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.design.widget.BottomNavigationView;
import android.support.v7.app.AppCompatActivity;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.SearchView;

import com.github.mikephil.charting.animation.Easing;
import com.github.mikephil.charting.charts.BarChart;
import com.github.mikephil.charting.charts.RadarChart;
import com.github.mikephil.charting.components.AxisBase;
import com.github.mikephil.charting.components.Description;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.data.BarData;
import com.github.mikephil.charting.data.BarDataSet;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.data.RadarData;
import com.github.mikephil.charting.data.RadarDataSet;
import com.github.mikephil.charting.data.RadarEntry;
import com.github.mikephil.charting.formatter.IAxisValueFormatter;
import com.github.mikephil.charting.utils.ColorTemplate;
import com.google.android.gms.auth.api.Auth;
import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.common.api.Status;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.Query;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.util.ArrayList;
import java.util.Date;

import javax.net.ssl.HttpsURLConnection;

import za.org.samac.harvest.util.AppUtil;

import static za.org.samac.harvest.MainActivity.farmerKey;

public class BarGraph extends AppCompatActivity {
    private BottomNavigationView bottomNavigationView;
    private FirebaseDatabase database;
    private DatabaseReference myRef;
    private DatabaseReference timeRef;
    private FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
    private String userUid;
    private String lastSession;
    private Date latestDate;
    private static String workerKey;
    private static final String TAG = "Analytics";
    private ArrayList<BarEntry> entries = new ArrayList<>();
    private com.github.mikephil.charting.charts.PieChart pieChart;
    private ProgressBar progressBar;
    private BarChart barChart;
    private com.github.mikephil.charting.charts.BarChart barGraphView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bar_graph);

        progressBar = findViewById(R.id.progressBar);
        barGraphView = findViewById(R.id.barChart);
        barChart = (BarChart) findViewById(R.id.barChart);

        bottomNavigationView = findViewById(R.id.BottomNav);
        bottomNavigationView.setSelectedItemId(R.id.actionSession);

        bottomNavigationView.setOnNavigationItemSelectedListener(
                new BottomNavigationView.OnNavigationItemSelectedListener() {
                    @Override
                    public boolean onNavigationItemSelected(@NonNull MenuItem item) {
                        switch (item.getItemId()) {
                            case R.id.actionYieldTracker:
                                Intent openMainActivity= new Intent(BarGraph.this, MainActivity.class);
                                openMainActivity.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
                                startActivityIfNeeded(openMainActivity, 0);
                                return true;
                            case R.id.actionInformation:
                                Intent openInformation= new Intent(BarGraph.this, InformationActivity.class);
                                openInformation.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
                                startActivityIfNeeded(openInformation, 0);
                                return true;
                            case R.id.actionSession:
                                return true;
                            case R.id.actionStats:
                                Intent openAnalytics= new Intent(BarGraph.this, Analytics.class);
                                openAnalytics.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
                                startActivityIfNeeded(openAnalytics, 0);
                                return true;
                        }
                        return true;
                    }
                });

        //Start the first fragment
        getSupportActionBar().setDisplayHomeAsUpEnabled(false);
        database = FirebaseDatabase.getInstance();
        userUid = user.getUid();//ID or key of the current user
        workerKey = getIntent().getStringExtra("key");
        getTotalBagsPerDay();
        //displayGraph();
    }

    private static String urlTotalBagsPerDay() {
        String base = "https://us-central1-harvest-ios-1522082524457.cloudfunctions.net/timedGraphSessions";
        return base;
    }

    private static String urlParameters() {
        String base = "";
        base = base + "id0=" + workerKey;
        base = base + "&groupBy=" + "worker";
        base = base + "&period=" + "hourly";
        double currentTime;
        double divideBy1000Var = 1000.0000000;
        currentTime = (System.currentTimeMillis()/divideBy1000Var);
        base = base + "&startDate=" + (currentTime - 7 * 24 * 60 * 10);
        base = base + "&endDate=" + currentTime;
        base = base + "&uid=" + farmerKey;

        return base;
    }

    // HTTP POST request
    private static String sendPost(String url, String urlParameters) throws Exception {
        URL obj = new URL(url);
        HttpsURLConnection con = (HttpsURLConnection) obj.openConnection();

        //add reuqest header
        con.setRequestMethod("POST");
        con.setRequestProperty("Accept-Language", "en-US,en;q=0.5");

        // Send post request
        con.setDoOutput(true);
        DataOutputStream wr = new DataOutputStream(con.getOutputStream());
        wr.writeBytes(urlParameters);
        wr.flush();
        wr.close();

        int responseCode = con.getResponseCode();
        System.out.println("\nSending 'POST' request to URL : " + url);
        System.out.println("Post parameters : " + urlParameters);
        System.out.println("Response Code : " + responseCode);

        BufferedReader in = new BufferedReader(
                new InputStreamReader(con.getInputStream()));
        String inputLine;
        StringBuffer response = new StringBuffer();

        while ((inputLine = in.readLine()) != null) {
            response.append(inputLine);
        }
        in.close();

        return response.toString();
    }

    public void getTotalBagsPerDay() {
        try {
            Thread thread = new Thread(new Runnable() {
                @Override
                public void run() {
                    try {
                        String response = sendPost(urlTotalBagsPerDay(), urlParameters());
                        JSONObject objs = new JSONObject(response);
                        System.out.println(" %%%%%%%%%%%%% " + response + " %%%%%%%%%%%%% " + objs.keys());
                        //put entries in graph
                        final String Sunday = "Sunday";
                        final String Monday = "Monday";
                        final String Tuesday = "Tuesday";
                        final String Wednesday = "Wednesday";
                        final String Thursday = "Thursday";
                        final String Friday = "Friday";
                        final String Saturday = "Saturday";
                        int totalSunday = 0;
                        int totalMonday = 0;
                        int totalTuesday = 0;
                        int totalWednesday = 0;
                        int totalThursday = 0;
                        int totalFriday = 0;
                        int totalSaturday = 0;
                        JSONObject objOrchard = objs.getJSONObject(workerKey);

                        if (objOrchard.has(Sunday) == true) {
                            totalSunday = objOrchard.getInt(Sunday);
                        }
                        if (objOrchard.has(Monday) == true) {
                            totalMonday = objOrchard.getInt(Monday);
                        }
                        if (objOrchard.has(Tuesday) == true) {
                            totalTuesday = objOrchard.getInt(Tuesday);
                        }
                        if (objOrchard.has(Wednesday) == true) {
                            totalWednesday = objOrchard.getInt(Wednesday);
                        }
                        if (objOrchard.has(Thursday) == true) {
                            totalThursday = objOrchard.getInt(Thursday);
                        }
                        if (objOrchard.has(Friday) == true) {
                            totalFriday = objOrchard.getInt(Friday);
                        }
                        if (objOrchard.has(Saturday) == true) {
                            totalSaturday = objOrchard.getInt(Saturday);
                        }

                        entries.add(new BarEntry(1, 10));
                        entries.add(new BarEntry(2, 20));
                        entries.add(new BarEntry(3, 30));
                        entries.add(new BarEntry(4, 40));
                        entries.add(new BarEntry(5, 50));
                        entries.add(new BarEntry(1, 10));
                        entries.add(new BarEntry(2, 20));
                        entries.add(new BarEntry(3, 30));
                        entries.add(new BarEntry(4, 40));
                        entries.add(new BarEntry(5, 50));

                        /*XAxis xAxis = barChart.getXAxis();
                        xAxis.setXOffset(0f);
                        xAxis.setYOffset(0f);
                        xAxis.setTextSize(8f);
                        xAxis.setValueFormatter(new IAxisValueFormatter() {

                            private String[] mFactors = new String[]{Sunday, Monday,
                                    Tuesday, Wednesday,
                                    Thursday, Friday, Saturday};

                            @Override
                            public String getFormattedValue(float value, AxisBase axis) {
                                return mFactors[(int) value % mFactors.length];
                            }
                        });*/

                        runOnUiThread(new Runnable() {
                            public void run() {
                                progressBar.setVisibility(View.GONE);//put progress bar until data is retrieved from firebase
                                barGraphView.setVisibility(View.VISIBLE);
                                barChart.animateY(1000, Easing.getEasingFunctionFromOption(Easing.EasingOption.EaseInBack));

                                BarDataSet dataset = new BarDataSet(entries, "Hours");
                                dataset.setColors(ColorTemplate.VORDIPLOM_COLORS);

                                BarData data = new BarData(dataset);//labels was one of the parameters
                                barChart.setData(data); // set the data and list of lables into chart

                                Description description = new Description();
                                description.setText("Per Hour Worker Performance");
                                barChart.setDescription(description);  // set the description
                                barChart.notifyDataSetChanged();
                            }
                        });
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            });

            thread.start();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    //Handle the menu
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item){
        switch (item.getItemId()){
            case R.id.search:
                return true;
            case R.id.settings:
                startActivity(new Intent(BarGraph.this, SettingsActivity.class));
                return true;
            case R.id.logout:
                FirebaseAuth.getInstance().signOut();
                if(!AppUtil.isUserSignedIn()){
                    startActivity(new Intent(BarGraph.this, LoginActivity.class));
                }
                else {
//                    FirebaseAuth.getInstance().signOut();
                }

                // Google sign out
                GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                        .requestIdToken(getString(R.string.default_web_client_id))
                        .requestEmail()
                        .build();

                Auth.GoogleSignInApi.signOut(LoginActivity.mGoogleSignInClient).setResultCallback(
                        new ResultCallback<Status>() {
                            @Override
                            public void onResult(@NonNull Status status) {
                                startActivity(new Intent(BarGraph.this, LoginActivity.class));
                            }
                        });
                finish();
                return true;
//            case R.id.homeAsUp:
//                onBackPressed();
//                return true;
            default:
                super.onOptionsItemSelected(item);
                return true;
        }
//        return false;
    }

}
