package za.org.samac.harvest.adapter;

import android.content.Context;
import android.content.Intent;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;
import java.util.TreeMap;

<<<<<<< HEAD
=======
import za.org.samac.harvest.BarGraph;
>>>>>>> 672409321bd6c7299473391a6a812faf411db6bd
import za.org.samac.harvest.PieChart;
import za.org.samac.harvest.R;
import za.org.samac.harvest.SessionItem;
import za.org.samac.harvest.Sessions;
import za.org.samac.harvest.domain.Foreman;

public class ForemanRecyclerViewAdapter extends RecyclerView.Adapter<ForemanRecyclerViewAdapter.ForemanViewHolder> {

<<<<<<< HEAD
    private ArrayList<String> dates;
    private TreeMap<String, SessionItem.Selection> sessions;
    private Context context;
    private Sessions sessionsClass;

    public ForemanRecyclerViewAdapter(Context applicationContext, Sessions sc) {
        this.context = applicationContext;
        sessionsClass = sc;
    }

    @Override
    public ForemanRecyclerViewAdapter.ForemanViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View itemView = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.sessions_grid_item, parent, false);

        return new ForemanRecyclerViewAdapter.ForemanViewHolder(itemView);
    }

    @Override
    public void onBindViewHolder(ForemanRecyclerViewAdapter.ForemanViewHolder holder, int position) {
        String date = dates.get(position);
        final SessionItem.Selection item = sessions.get(date);

        holder.sessionForeman.setText(item.foreman + " - " + dates.get(position));
        holder.sessionForeman.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent details = new Intent(context, SessionDetails.class);
                details.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                Intent key = details.putExtra("key", item.key);
                Intent sdate = details.putExtra("start_date", item.startDate);
                Intent wkey = details.putExtra("wid", item.foreman);
=======
    private Context context;
    private ArrayList<String> foremen;
    private ArrayList<String> foremenKeys;

    public ForemanRecyclerViewAdapter(Context applicationContext, ArrayList<String> foremen, ArrayList<String> foremenKeys) {
        this.context = applicationContext;
        this.foremen = foremen;
        this.foremenKeys = foremenKeys;
    }

    @Override
    public ForemanViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View itemView = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.activity_foremen_buttons, parent, false);

        return new ForemanViewHolder(itemView);
    }

    @Override
    public void onBindViewHolder(ForemanViewHolder holder, int position) {
        final String foremenName = this.foremen.get(position);
        final String foremenKey = this.foremenKeys.get(position);
        holder.button.setText(foremenName);//set name of orchard
        holder.button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent details = new Intent(context, BarGraph.class);
                details.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

                Intent key = details.putExtra("key", foremenKey);
>>>>>>> 672409321bd6c7299473391a6a812faf411db6bd

                context.startActivity(details);
            }
        });
<<<<<<< HEAD

        if (position == dates.size() - 1) {
            sessionsClass.getNewPage();
        }
=======
>>>>>>> 672409321bd6c7299473391a6a812faf411db6bd
    }

    @Override
    public int getItemCount() {
<<<<<<< HEAD
        return this.dates.size();
    }



    public void setSessions(TreeMap<String, SessionItem.Selection> sessions) {
        this.sessions = sessions;
    }

    public void setDates(ArrayList<String> dates) {
        this.dates = dates;
    }

    public class ForemanViewHolder extends RecyclerView.ViewHolder {
        TextView dateOfSession;
        Button sessionForeman;

        ForemanViewHolder(View view) {
            super(view);
            sessionForeman = view.findViewById(R.id.sessionForeman);
=======
        return this.foremen.size();
    }

    public class ForemanViewHolder extends RecyclerView.ViewHolder {
        Button button;

        ForemanViewHolder(View view) {
            super(view);
            button = view.findViewById(R.id.foremanGraph);
>>>>>>> 672409321bd6c7299473391a6a812faf411db6bd
        }
    }
}
