package za.org.samac.harvest;

import android.content.Intent;
import android.media.MediaCas;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.design.widget.BottomNavigationView;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.MenuItem;

import com.github.mikephil.charting.components.Description;
import com.github.mikephil.charting.data.PieData;
import com.github.mikephil.charting.data.PieDataSet;
import com.github.mikephil.charting.data.PieEntry;
import com.github.mikephil.charting.utils.ColorTemplate;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.Query;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.Map;

public class PieChart extends AppCompatActivity {
    private BottomNavigationView bottomNavigationView;
    private FirebaseDatabase database;
    private DatabaseReference myRef;
    private FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
    private Query query;
    private static final String TAG = "Analytics";
    ArrayList<PieEntry> entries = new ArrayList<>();
    com.github.mikephil.charting.charts.PieChart pieChart;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_pie_chart);

        bottomNavigationView = findViewById(R.id.BottomNav);
        bottomNavigationView.setSelectedItemId(R.id.actionSession);

        bottomNavigationView.setOnNavigationItemSelectedListener(
                new BottomNavigationView.OnNavigationItemSelectedListener() {
                    @Override
                    public boolean onNavigationItemSelected(@NonNull MenuItem item) {
                        switch (item.getItemId()) {
                            case R.id.actionYieldTracker:
                                Intent openMainActivity= new Intent(PieChart.this, MainActivity.class);
                                openMainActivity.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
                                startActivityIfNeeded(openMainActivity, 0);
                                return true;
                            case R.id.actionInformation:
                                Intent openInformation= new Intent(PieChart.this, InformationActivity.class);
                                openInformation.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
                                startActivityIfNeeded(openInformation, 0);
                                return true;
                            case R.id.actionSession:
                                return true;
                            case R.id.actionStats:
                                Intent openPieChart= new Intent(PieChart.this, Analytics.class);
                                openPieChart.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
                                startActivityIfNeeded(openPieChart, 0);
                                return true;

                        }
                        return true;
                    }
                });

        //Start the first fragment
        getSupportActionBar().setDisplayHomeAsUpEnabled(false);
        displayGraph();
    }

    public void displayGraph() {
        database = FirebaseDatabase.getInstance();
        String userUid = user.getUid();//ID or key of the current user
        myRef = database.getReference(userUid + "/sessions/");//path to sessions increment in Firebase

        query = myRef.limitToLast(1);

        pieChart = (com.github.mikephil.charting.charts.PieChart)findViewById(R.id.pieChart);

        query.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                for (DataSnapshot zoneSnapshot: dataSnapshot.getChildren()) {
                    Map<String, Object> collection = (Map<String, Object>) zoneSnapshot.child("collections").getValue();
                    for (String workerID :
                            collection.keySet()) {
                        Integer yield = ((ArrayList<Object>)collection.get(workerID)).size();
                        entries.add(new PieEntry((float)yield, workerID));
                    }
                }

                PieDataSet dataset = new PieDataSet(entries, "# of Calls");
                dataset.setColors(ColorTemplate.VORDIPLOM_COLORS);

                PieData data = new PieData(dataset);//labels was one of the parameters
                pieChart.setData(data); // set the data and list of lables into chart

                Description description = new Description();
                description.setText("Description");
                pieChart.setDescription(description); // set the description
                pieChart.notifyDataSetChanged();
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {
                Log.w(TAG, "onCancelled", databaseError.toException());
            }
        });
    }
}
