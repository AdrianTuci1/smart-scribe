import React from 'react';

const DeviceMockup = () => {
    return (
        <div className="relative w-full max-w-[950px] h-[600px]">
            {/* Container with overflow hidden for background and desktop */}
            <div className="absolute inset-0 overflow-hidden rounded-[48px]">
                {/* Background Image - Blurred photo */}
                <div className="absolute inset-0 rounded-[48px] overflow-hidden">
                    <div
                        className="w-full h-full bg-cover bg-center"
                        style={{
                            backgroundImage: 'url(/gen05.png)',
                        }}
                    ></div>
                </div>

                {/* Main Desktop Mockup - Partial View with White Border */}
                <div className="absolute left-8 top-8 w-[850px] h-[520px] bg-white rounded-[32px] shadow-2xl p-3 overflow-hidden">
                    <div className="w-full h-full bg-[#1a1a1a] rounded-[24px] border border-white/10 flex text-white font-sans text-sm select-none">
                        {/* Sidebar */}
                        <div className="w-56 bg-[#1a1a1a] border-r border-white/5 flex flex-col p-3">
                            {/* Brand */}
                            <div className="flex items-center gap-2 mb-6 px-2">
                                <div className="w-7 h-7 bg-orange-500 rounded-lg flex items-center justify-center text-[10px] font-bold text-black">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                                        <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" />
                                    </svg>
                                </div>
                                <span className="font-medium text-white text-sm">Flowin Workspace</span>
                            </div>

                            {/* Navigation */}
                            <div className="space-y-1">
                                <NavItem icon={<HomeIcon />} label="Home" active={false} />
                                <NavItem icon={<SearchIcon />} label="Search" active={false} />
                                <NavItem icon={<InboxIcon />} label="Inbox" active={false} />
                            </div>

                            {/* Favorites */}
                            <div className="mt-6">
                                <div className="text-xs font-medium text-gray-500 mb-2 px-2">Favorites</div>
                                <div className="space-y-1">
                                    <NavItem icon={<BulbIdesIcon />} label="Crazy product ideas" active={true} />
                                    <NavItem icon={<CheckSquareIcon />} label="My to dos" active={false} />
                                </div>
                            </div>
                        </div>

                        {/* Main Content */}
                        <div className="flex-1 bg-[#1a1a1a] p-10 overflow-hidden relative">
                            {/* Header */}
                            <div className="mb-8">
                                <div className="flex items-center gap-3">
                                    <div className="text-yellow-200">
                                        <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor" stroke="none">
                                            <path d="M9 21c0 .55.45 1 1 1h4c.55 0 1-.45 1-1v-1H9v1zm3-19C8.14 2 5 5.14 5 9c0 2.38 1.19 4.47 3 5.74V17c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-2.26c1.81-1.27 3-3.36 3-5.74 0-3.86-3.14-7-7-7z" />
                                        </svg>
                                    </div>
                                    <h1 className="text-3xl font-semibold tracking-tight">Crazy product ideas</h1>
                                </div>
                            </div>

                            {/* Section Title */}
                            <h2 className="text-lg font-medium mb-6">Physical Products</h2>

                            {/* List Items */}
                            <div className="space-y-5 pl-1">
                                <ListItem
                                    title="Self-Watering Plant Shoes"
                                    description="Sneakers with built-in planters and a tiny water reservoir. Walk, water, grow!"
                                />
                                <ListItem
                                    title="Mood Color Changing Wallpaper"
                                    description="Smart wallpaper that shifts color based on your mood (sensed via wearable or app)."
                                />
                                <ListItem
                                    title="Portable Nap Pod Backpack"
                                    description="Backpack unfolds into a private, soundproof nap cocoon. For airports, parks, anywhere!"
                                />
                                <ListItem
                                    title="Pet Translator Collar"
                                    description="Collar for dogs/cats that translates barks/meows into human speech (or at least tries)."
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
            <div className="absolute left-20 bottom-[-50px] w-[240px] h-[500px] bg-[#1a1a1a] rounded-[40px] shadow-2xl border-[8px] border-gray-300 flex flex-col text-white font-sans select-none overflow-hidden z-10">
                {/* Mobile Status Bar */}
                <div className="h-10 bg-[#1a1a1a] flex items-center justify-center relative pt-2">
                    <div className="w-28 h-6 bg-[#1a1a1a] rounded-b-2xl absolute top-0"></div>
                </div>

                {/* Mobile Content - Full Screen */}
                <div className="flex-1 bg-[#1a1a1a] px-6 py-4 overflow-hidden flex flex-col">
                    {/* Header */}
                    <div className="mb-6">
                        <div className="flex items-center gap-2">
                            <div className="text-yellow-200">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" stroke="none">
                                    <path d="M9 21c0 .55.45 1 1 1h4c.55 0 1-.45 1-1v-1H9v1zm3-19C8.14 2 5 5.14 5 9c0 2.38 1.19 4.47 3 5.74V17c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-2.26c1.81-1.27 3-3.36 3-5.74 0-3.86-3.14-7-7-7z" />
                                </svg>
                            </div>
                            <h1 className="text-lg font-semibold">Crazy product ideas</h1>
                        </div>
                    </div>

                    {/* Section Title */}
                    <h2 className="text-sm font-medium mb-4 text-gray-200">Physical Products</h2>

                    {/* List Items - Mobile */}
                    <div className="space-y-4 flex-1">
                        <MobileListItem
                            title="Self-Watering Plant Shoes"
                            description="Sneakers with built-in planters and a tiny water reservoir. Walk, water, grow!"
                        />
                        <MobileListItem
                            title="Mood Color Changing Wallpaper"
                            description="Smart wallpaper that shifts color based on your mood (sensed via wearable or app)."
                        />
                        <MobileListItem
                            title="Portable Nap Pod Backpack"
                            description="Backpack unfolds into a private, soundproof nap cocoon. For airports, parks, anywhere!"
                        />
                    </div>
                </div>

                {/* Bottom Overlay - Waveform Card */}
                <div className="bg-[#1a1a1a] p-4 border-t border-white/5">
                    <div className="bg-[#252525] rounded-3xl p-4 flex flex-col gap-4">
                        {/* Action Buttons */}
                        <div className="flex justify-between items-center">
                            <button className="w-10 h-10 rounded-full bg-[#3a3a3a] flex items-center justify-center text-white/70">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                    <line x1="18" y1="6" x2="6" y2="18"></line>
                                    <line x1="6" y1="6" x2="18" y2="18"></line>
                                </svg>
                            </button>
                            <button className="w-10 h-10 rounded-full bg-white flex items-center justify-center text-black">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                                    <polyline points="20 6 9 17 4 12"></polyline>
                                </svg>
                            </button>
                        </div>

                        {/* Waveform */}
                        <div className="h-16 flex items-center justify-center">
                            <MobileAudioWaveform />
                        </div>

                        {/* Globe Icon */}
                        <div className="flex justify-center">
                            <div className="w-10 h-10 rounded-full bg-[#3a3a3a] flex items-center justify-center">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                    <circle cx="12" cy="12" r="10"></circle>
                                    <line x1="2" y1="12" x2="22" y2="12"></line>
                                    <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
                                </svg>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Home Indicator */}
                <div className="h-6 bg-[#1a1a1a] flex items-center justify-center pb-2">
                    <div className="w-32 h-1 bg-white/30 rounded-full"></div>
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

const MobileAudioWaveform = () => (
    <div className="flex items-center justify-center gap-[2px] h-full">
        {[30, 50, 35, 70, 40, 80, 50, 35, 60, 45, 25, 50, 70, 45, 80, 55, 40, 65, 35, 25, 45, 60, 40, 75, 50].map((h, i) => (
            <div
                key={i}
                className="w-[2px] bg-white rounded-full"
                style={{ height: `${h}%` }}
            ></div>
        ))}
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

const AudioWaveform = () => (
    <div className="flex items-center justify-center gap-[3px] w-full h-full">
        {[40, 60, 45, 80, 50, 90, 60, 40, 70, 50, 30, 60, 80, 50, 90, 60, 45, 70, 40, 30].map((h, i) => (
            <div
                key={i}
                className="w-1 bg-white rounded-full"
                style={{ height: `${h}%` }}
            ></div>
        ))}
    </div>
)

export default DeviceMockup;
