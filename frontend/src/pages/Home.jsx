import React from 'react';
import Hero from '../components/Hero';
import TargetUsers from '../components/TargetUsers';
import AnyDevice from '../components/AnyDevice';
import Features from '../components/Features';
import International from '../components/International';

const Home = () => {
    return (
        <main>
            <Hero />
            <TargetUsers />
            <AnyDevice />
            <Features />
            <International />
        </main>
    );
};

export default Home;
