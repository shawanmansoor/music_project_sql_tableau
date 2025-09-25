# Spotify Music Analytics Project 🎵

## 📌 Overview
This project explores the database **Spotify Top 25 tracks* using **MySQL** for data preparation and **Tableau** for visualization of the findings.
The goal was to analyze **streaming trends, seasonal patterns, and musical characteristics** that drive song popularity.

My means for pursuing this project is my passion for music and its intricacies.
Everyone knows that certain artists simply pull more streams (Drake, Taylor Swift, The Weeknd, etc.), but no one speaks about how different song features (BPM, danceability, etc.) and external factors (season, year) affect streaming numbers. 

## ⚙️ Tech Stack
- **SQL (MySQL Workbench)** → Data cleaning, transformations, and creation of analytical views  
- **Tableau** → Interactive dashboards and KPIs for insights  
- **GitHub** → Version control and project documentation

## 🗂️ Data Preparation (MySQL)
My first step was finding a database that had not only the artists, song, and streams, but also specific song features, like BPM, danceability, energy, etc.
I came across one on Kaggle and connected it to MySQL workbench to do some data cleaning
I also created SQL **views** to aggregate data by:
  - **Popularity** (Quartiles to show tiers of popularity from bottom 25% to top 25%)
  - **Song Features** (see song feature averages and if it affects the popularity of the track)
  - **Year** (see what year(s) dominated streams/made the top 25 threshold)
  - **Season** (Winter, Spring, Summer, Fall - the trend of the number of streams, popular tracks, and average BPM of each season)
  - **Key & Mode** (e.g., C Major, A Minor, the trend of key and mode in relation to season)


