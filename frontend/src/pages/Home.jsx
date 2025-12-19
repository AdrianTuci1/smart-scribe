import React from 'react';
import Hero from '../components/Hero';
import SmartTranscript from '../components/SmartTranscript';
import TargetUsers from '../components/TargetUsers';
import AnyDevice from '../components/AnyDevice';
import Features from '../components/Features';

const Home = () => {
    return (
        <main>
            <Hero />
            <SmartTranscript />
            <TargetUsers />
            <AnyDevice />
            <Features />
        </main>
    );
};

export default Home;
