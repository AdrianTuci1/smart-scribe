import React from 'react';
import './DeviceMockup.css';

const DeviceMockup = () => {
    return (
        <div className="device-mockup-container">
            {/* Container with overflow hidden for background and desktop */}
            <div className="dm-bg-container">
                {/* Background Image - Blurred photo */}
                <div className="dm-bg-wrapper">
                    <div
                        className="dm-bg-image"
                        style={{
                            backgroundImage: 'url(/gen05.png)',
                        }}
                    ></div>
                </div>

                {/* Main Desktop Mockup - Partial View with White Border */}
                <div className="desktop-mockup">
                    <div className="desktop-inner">
                        {/* Sidebar */}
                        <div className="desktop-sidebar">
                            {/* Brand */}
                            <div className="flex items-center gap-2 mb-6 px-2">
                                <div className="w-7 h-7 bg-orange-500 rounded-lg flex items-center justify-center text-[10px] font-bold text-black">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                                        <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" />
                                    </svg>
                                </div>
                                <span className="font-medium text-white text-sm">Galactic Notes 🚀</span>
                            </div>

                            {/* Navigation */}
                            <div className="space-y-1">
                                <NavItem icon={<HomeIcon />} label="Base Station" active={false} />
                                <NavItem icon={<SearchIcon />} label="Scan Sector" active={false} />
                                <NavItem icon={<InboxIcon />} label="Comms" active={false} />
                            </div>

                            {/* Favorites */}
                            <div className="mt-6">
                                <div className="text-xs font-medium text-gray-500 mb-2 px-2">Priority Missions</div>
                                <div className="space-y-1">
                                    <NavItem icon={<BulbIdesIcon />} label="Conquer Universe" active={true} />
                                    <NavItem icon={<CheckSquareIcon />} label="Daily Quests" active={false} />
                                </div>
                            </div>
                        </div>

                        {/* Main Content */}
                        <div className="desktop-content">
                            {/* Header */}
                            <div className="mb-8">
                                <div className="flex items-center gap-3">
                                    <div className="text-yellow-200">
                                        <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor" stroke="none">
                                            <path d="M9 21c0 .55.45 1 1 1h4c.55 0 1-.45 1-1v-1H9v1zm3-19C8.14 2 5 5.14 5 9c0 2.38 1.19 4.47 3 5.74V17c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-2.26c1.81-1.27 3-3.36 3-5.74 0-3.86-3.14-7-7-7z" />
                                        </svg>
                                    </div>
                                    <h1 className="text-3xl font-semibold tracking-tight">Conquer Universe</h1>
                                </div>
                            </div>

                            {/* Section Title */}
                            <h2 className="text-lg font-medium mb-6">Top Secret Plans</h2>

                            {/* List Items */}
                            <div className="space-y-5 pl-1">
                                <ListItem
                                    title="Mars Colony Blueprint"
                                    description="Architectural designs for the first self-sustaining city on Mars."
                                />
                                <ListItem
                                    title="Alien Language Decoder"
                                    description="AI model trained on intergalactic radio signals to break the code."
                                />
                                <ListItem
                                    title="Teleportation Device"
                                    description="Prototype testing for instant travel between headquarters."
                                />
                                <ListItem
                                    title="Infinite Pizza Generator"
                                    description="Solving world hunger, one slice at a time. Cheese stuffed crust included."
                                />
                            </div>

                            {/* Floating Waveform Badge */}
                            <div className="absolute bottom-10 right-10">
                                <div className="border-2 border-white/40 rounded-full px-5 py-2.5 flex items-center gap-1">
                                    <Waveform />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Mobile Mockup - Outside overflow container, positioned on the left, extending outside bottom */}
            <div className="mobile-mockup">
                {/* Mobile Status Bar */}
                <div className="mobile-status-bar">
                    <div className="mobile-notch"></div>
                </div>

                {/* Mobile Content - Full Screen */}
                <div className="mobile-content">
                    {/* Header */}
                    <div className="mb-6">
                        <div className="flex items-center gap-2">
                            <div className="text-yellow-200">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" stroke="none">
                                    <path d="M9 21c0 .55.45 1 1 1h4c.55 0 1-.45 1-1v-1H9v1zm3-19C8.14 2 5 5.14 5 9c0 2.38 1.19 4.47 3 5.74V17c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-2.26c1.81-1.27 3-3.36 3-5.74 0-3.86-3.14-7-7-7z" />
                                </svg>
                            </div>
                            <h1 className="text-lg font-semibold">Conquer Universe</h1>
                        </div>
                    </div>

                    {/* Section Title */}
                    <h2 className="text-sm font-medium mb-4 text-gray-200">Top Secret Plans</h2>

                    {/* List Items - Mobile */}
                    <div className="space-y-4 flex-1">
                        <MobileListItem
                            title="Mars Colony Blueprint"
                            description="Designs for the first city on Mars."
                        />
                        <MobileListItem
                            title="Alien Language Decoder"
                            description="AI model to break the code."
                        />
                        <MobileListItem
                            title="Teleportation Device"
                            description="Instant travel prototype."
                        />
                    </div>
                </div>

                {/* Bottom Overlay - Waveform Card */}
                <div className="mobile-bottom-overlay">
                    <div className="mobile-card-container">
                        {/* Action Buttons */}
                        <div className="mobile-action-buttons">
                            <button className="mobile-btn-secondary">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                    <line x1="18" y1="6" x2="6" y2="18"></line>
                                    <line x1="6" y1="6" x2="18" y2="18"></line>
                                </svg>
                            </button>
                            <button className="mobile-btn-primary">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                                    <polyline points="20 6 9 17 4 12"></polyline>
                                </svg>
                            </button>
                        </div>

                        {/* Waveform / Orb */}
                        <div className="mobile-waveform-container">
                            <div className="dm-orb"></div>
                        </div>

                        {/* Globe Icon */}
                        <div className="mobile-globe-wrapper">
                            <div className="mobile-globe-icon">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                    <circle cx="12" cy="12" r="10"></circle>
                                    <line x1="2" y1="12" x2="22" y2="12"></line>
                                    <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
                                </svg>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

const NavItem = ({ icon, label, active }) => (
    <div className={`flex items-center gap-3 px-3 py-2 rounded-lg ${active ? 'bg-white/10 text-white' : 'text-gray-400'}`}>
        <div className="w-4 h-4 text-current">
            {icon}
        </div>
        <span className="text-sm font-medium">{label}</span>
    </div>
);

const ListItem = ({ title, description }) => (
    <div className="flex gap-3">
        <div className="mt-1.5 w-1.5 h-1.5 rounded-full bg-gray-400" />
        <div>
            <h3 className="font-medium text-white text-sm">{title}</h3>
            <p className="text-gray-400 text-xs leading-relaxed max-w-md">{description}</p>
        </div>
    </div>
);

const MobileListItem = ({ title, description }) => (
    <div className="flex gap-2">
        <div className="mt-1.5 w-1 h-1 rounded-full bg-gray-500" />
        <div>
            <h3 className="font-medium text-white text-xs">{title}</h3>
            <p className="text-gray-400 text-[10px] leading-relaxed">{description}</p>
        </div>
    </div>
);


/* Icons */
const HomeIcon = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
        <polyline points="9 22 9 12 15 12 15 22"></polyline>
    </svg>
);
const SearchIcon = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="11" cy="11" r="8"></circle>
        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
    </svg>
);
const InboxIcon = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path>
        <polyline points="22,6 12,13 2,6"></polyline>
    </svg>
);
const BulbIdesIcon = () => (
    <svg viewBox="0 0 24 24" fill="currentColor" stroke="none">
        <path d="M9 21c0 .55.45 1 1 1h4c.55 0 1-.45 1-1v-1H9v1zm3-19C8.14 2 5 5.14 5 9c0 2.38 1.19 4.47 3 5.74V17c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-2.26c1.81-1.27 3-3.36 3-5.74 0-3.86-3.14-7-7-7z" />
    </svg>
);
const CheckSquareIcon = () => (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-green-500 fill-green-500/0">
        <rect x="3" y="3" width="18" height="18" rx="2" ry="2" className="fill-green-600 stroke-none"></rect>
        <path d="M9 12l2 2 4-4" stroke="white"></path>
    </svg>
);

const Waveform = () => (
    <div className="flex gap-1 h-5 items-center">
        {[...Array(12)].map((_, i) => (
            <div key={i} className="w-0.5 bg-white rounded-full animate-pulse" style={{ height: `${Math.random() * 100}%`, animationDelay: `${i * 0.1}s` }} />
        ))}
    </div>
)

export default DeviceMockup;
