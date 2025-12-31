import LiveUserGlobe from './components/Dashboard/LiveUserGlobe';
import ActivityHeatmap from './components/Dashboard/ActivityHeatmap';
import IntegrationsColumn from './components/Dashboard/IntegrationsColumn';
import SystemLoadWidget from './components/Dashboard/SystemLoadWidget';
import SubscriptionRiskList from './components/Dashboard/SubscriptionRiskList';
import './styles/global.css';
import './styles/dashboard.css';

function App() {
  return (
    <div className="dashboard-root">
      {/* Content Overlay */}
      <div className="dashboard-layout">

        {/* TOP SECTION: 3 Columns */}
        <div className="dashboard-top">

          {/* LEFT COLUMN - Single Panel with Metric + Churn Risk */}
          <div className="floating-panel floating-panel--flex dashboard-column--left">
            {/* Words Metric inside panel */}
            <div className="panel-metric-header">
              <span className="panel-metric-label">Words Transcribed Today</span>
              <span className="panel-metric-value">1,847,293</span>
              <span className="panel-metric-subtext">Last 24 hours</span>
            </div>

            <div className="panel-divider" />

            <h3 className="section-title">Churn Risk</h3>
            <div className="custom-scroll scroll-container">
              <SubscriptionRiskList />
            </div>
          </div>

          {/* CENTER - Globe Panel with globe inside */}
          <div className="floating-panel globe-panel">
            <LiveUserGlobe />
          </div>

          {/* RIGHT COLUMN - Single Panel with Header + Stream */}
          <div className="floating-panel floating-panel--flex dashboard-column--right">
            {/* Header inside panel */}
            <div className="floating-panel__header-row">
              <span className="label-sm">Top Integrations</span>
              <span className="floating-panel__realtime">Real-Time</span>
            </div>

            <div className="panel-divider" />

            <div className="scroll-container custom-scroll">
              <IntegrationsColumn />
            </div>
          </div>
        </div>

        {/* BOTTOM SECTION: Full Width Row */}
        <div className="dashboard-bottom">
          {/* Contribution Graph */}
          <div className="floating-panel floating-panel--flex" style={{ flexDirection: 'row', gap: 24 }}>
            {/* Left: Title + Metric */}
            <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', minWidth: 140 }}>
              <h3 className="label-sm section-title--simple">Contribution Graph</h3>
              <div className="code-lines-metric" style={{ alignItems: 'flex-start' }}>
                <span className="code-lines-value">12,847</span>
                <span className="code-lines-label">Paying Users</span>
              </div>
            </div>

            {/* Right: Heatmap */}
            <div style={{ flex: 1, minWidth: 0 }}>
              <ActivityHeatmap />
            </div>
          </div>

          {/* System Load Widget */}
          <div className="floating-panel floating-panel--flex">
            <SystemLoadWidget />
          </div>
        </div>

      </div>
    </div>
  );
}

export default App;
