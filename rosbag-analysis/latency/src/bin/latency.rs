// mod state;

use anyhow::Result;
use clap::Parser;
use futures::stream::TryStreamExt;
use itertools::Itertools;
use sqlx::{sqlite::SqlitePoolOptions, FromRow};
use std::{collections::HashMap, time::Duration};

///
use r2r::{
    builtin_interfaces::msg::Time,
    geometry_msgs::msg::PoseStamped,
    sensor_msgs::msg::{PointCloud2, PointField},
    std_msgs::msg::Header,
};
///

/// Rosbag2 merging tool.
#[derive(Parser)]
struct Opts {
    /// A list of input rosbag2 files to be merged together.
    pub input_bag: String,
}

#[derive(Debug, Clone, FromRow)]
struct Topic {
    pub id: u32,
    pub name: String,
    // pub r#type: String,
    // pub serialization_format: String,
    // pub offered_qos_profiles: String,
}

#[derive(Debug, Clone, FromRow)]
struct Message {
    // pub id: u32,
    pub topic_id: u32,
    pub timestamp: i64,
    pub data: Vec<u8>,
}

#[derive(Debug, Clone)]
struct LatencyStat {
    pub min: Duration,
    pub max: Duration,
    pub med: Duration,
}

#[async_std::main]
async fn main() -> Result<()> {
    let opts = Opts::parse();

    /* These mnemonics are used. */
    // f: file
    // c: database connection
    // t: topic
    // tv: topic vec
    // ti: topic id
    // tn: topic name
    // x_to_y: a map from x to y

    // Open input sqlite databases
    let pool = {
        let uri = format!("sqlite://{}", opts.input_bag);
        SqlitePoolOptions::new().connect(&uri).await?
    };

    // Read topics from the input database
    let tv: Vec<Topic> = sqlx::query_as("SELECT * FROM topics")
        .fetch_all(&pool)
        .await?;

    let ti_to_t: HashMap<u32, &Topic> = tv.iter().map(|topic| (topic.id, topic)).collect();

    let messages: Vec<_> = sqlx::query_as::<_, Message>("SELECT * FROM messages")
        .fetch(&pool)
        .try_collect()
        .await?;

    let groups: HashMap<&String, Vec<Message>> = messages
        .into_iter()
        .map(|msg| {
            let tn = &ti_to_t[&msg.topic_id].name;

            (tn, msg)
        })
        .into_group_map();

    let velodyne_points_group = groups
        .iter()
        .filter(|(tn, messages)| ***tn == String::from("/velodyne_points"));
    if velodyne_points_group.clone().count() == 0 {
        // println!("No /velodyne_points");
        panic!("No \"/velodyne_points\"!!!!")
    }
    // dbg!(velodyne_points_group);
    let mut latencies: Vec<LatencyStat> = velodyne_points_group
        .into_iter()
        .filter_map(|(tn, messages)| {
            let mut diffs: Vec<_> = {
                // ROS messages are encoded in CDR (Common Data Representation)
                // Let's decode it that way.
                messages
                    .into_iter()
                    .map(|msg| {
                        // ROS messages are encoded in CDR (Common Data Representation)
                        // Let's decode it that way.
                        let point_cloud: PointCloud2 = cdr::deserialize(&msg.data).unwrap();

                        // Access the timestamp in the header
                        let Time { sec, nanosec } = point_cloud.header.stamp;

                        // Convert to Rust's Duration, a common type to represent a
                        // period of time. (and support arithmetic)
                        let time =
                            Duration::from_nanos(sec as u64 * 1_000_000_000 + nanosec as u64);
                        let msg_timestamp = Duration::from_micros(msg.timestamp as u64);
                        msg_timestamp - time
                    })
                    .collect()
            };

            diffs.sort();
            dbg!(&diffs);
            let min = *diffs.first()?;
            let max = *diffs.last()?;
            let med = *diffs.get(diffs.len() / 2)?;

            // let (min, max) = diffs.minmax().into_option()?;

            Some(LatencyStat {
                min,
                max,
                med,
                // avg,
            })
        })
        .collect();

    latencies.iter().for_each(|(stat)|{
        let LatencyStat{min,max,med} = stat;
        println!("Latency of packets carrying velodyne points:\nmin: {:?}\nmax: {:?}\nmed: {:?}",min,max,med);
    });

    Ok(())
}
