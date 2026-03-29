import React, { useState, useEffect, useMemo } from 'react';
import { 
  Plus, 
  Users, 
  Milk, 
  CreditCard, 
  BarChart3, 
  Settings, 
  LogOut, 
  Search, 
  Download, 
  ChevronRight, 
  AlertCircle,
  Menu,
  X,
  Bell,
  Trash2,
  Edit2
} from 'lucide-react';
import { 
  auth, 
  db 
} from './firebase';
import { 
  signInWithPopup, 
  GoogleAuthProvider, 
  onAuthStateChanged, 
  signOut,
  User as FirebaseUser
} from 'firebase/auth';
import { 
  collection, 
  doc, 
  setDoc, 
  getDoc, 
  getDocs, 
  onSnapshot, 
  query, 
  orderBy, 
  addDoc, 
  deleteDoc, 
  updateDoc,
  Timestamp,
  getDocFromServer
} from 'firebase/firestore';
import { 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer, 
  AreaChart, 
  Area 
} from 'recharts';
import * as XLSX from 'xlsx';
import { format, startOfMonth, endOfMonth, isWithinInterval } from 'date-fns';
import { motion, AnimatePresence } from 'motion/react';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

// --- Utility ---
function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// --- Types ---
enum OperationType {
  CREATE = 'create',
  UPDATE = 'update',
  DELETE = 'delete',
  LIST = 'list',
  GET = 'get',
  WRITE = 'write',
}

interface FirestoreErrorInfo {
  error: string;
  operationType: OperationType;
  path: string | null;
  authInfo: {
    userId: string | undefined;
    email: string | null | undefined;
    emailVerified: boolean | undefined;
    isAnonymous: boolean | undefined;
    tenantId: string | null | undefined;
    providerInfo: any[];
  }
}

function handleFirestoreError(error: unknown, operationType: OperationType, path: string | null) {
  const errInfo: FirestoreErrorInfo = {
    error: error instanceof Error ? error.message : String(error),
    authInfo: {
      userId: auth.currentUser?.uid,
      email: auth.currentUser?.email,
      emailVerified: auth.currentUser?.emailVerified,
      isAnonymous: auth.currentUser?.isAnonymous,
      tenantId: auth.currentUser?.tenantId,
      providerInfo: auth.currentUser?.providerData.map(provider => ({
        providerId: provider.providerId,
        displayName: provider.displayName,
        email: provider.email,
        photoUrl: provider.photoURL
      })) || []
    },
    operationType,
    path
  }
  console.error('Firestore Error: ', JSON.stringify(errInfo));
  throw new Error(JSON.stringify(errInfo));
}

interface UserProfile {
  uid: string;
  email: string;
  name: string;
  role: 'admin' | 'user';
}

interface Farmer {
  id: string;
  name: string;
  phone: string;
  location: string;
  joinedAt: any;
}

interface MilkCollection {
  id: string;
  farmerId: string;
  amount: number;
  quality: number;
  timestamp: any;
  collectedBy: string;
}

interface Payment {
  id: string;
  farmerId: string;
  amount: number;
  period: string;
  status: 'pending' | 'paid';
  timestamp: any;
}

// --- Components ---

const ErrorBoundary = ({ children }: { children: React.ReactNode }) => {
  const [hasError, setHasError] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  useEffect(() => {
    const handleError = (event: ErrorEvent) => {
      if (event.error?.message?.startsWith('{')) {
        try {
          const info = JSON.parse(event.error.message) as FirestoreErrorInfo;
          setErrorMsg(`Firestore Error: ${info.operationType} on ${info.path} failed. ${info.error}`);
        } catch {
          setErrorMsg(event.error.message);
        }
      } else {
        setErrorMsg(event.error?.message || 'An unknown error occurred');
      }
      setHasError(true);
    };

    window.addEventListener('error', handleError);
    return () => window.removeEventListener('error', handleError);
  }, []);

  if (hasError) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-red-50 p-4">
        <div className="bg-white p-8 rounded-2xl shadow-xl max-w-md w-full text-center">
          <AlertCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Something went wrong</h2>
          <p className="text-gray-600 mb-6">{errorMsg}</p>
          <button 
            onClick={() => window.location.reload()}
            className="w-full py-3 bg-red-600 text-white rounded-xl font-semibold hover:bg-red-700 transition-colors"
          >
            Reload Application
          </button>
        </div>
      </div>
    );
  }

  return <>{children}</>;
};

export default function App() {
  const [user, setUser] = useState<FirebaseUser | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  // Data State
  const [farmers, setFarmers] = useState<Farmer[]>([]);
  const [collections, setCollections] = useState<MilkCollection[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);

  // Auth Listener
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (u) => {
      setUser(u);
      if (u) {
        try {
          const docRef = doc(db, 'users', u.uid);
          const docSnap = await getDoc(docRef);
          
          if (docSnap.exists()) {
            setProfile(docSnap.data() as UserProfile);
          } else {
            // Create profile if not exists
            const newProfile: UserProfile = {
              uid: u.uid,
              email: u.email || '',
              name: u.displayName || 'User',
              role: u.email === 'Billmatoya@gmail.com' ? 'admin' : 'user'
            };
            await setDoc(docRef, newProfile);
            setProfile(newProfile);
          }
        } catch (error) {
          console.error("Error fetching profile:", error);
        }
      } else {
        setProfile(null);
      }
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  // Connection Test
  useEffect(() => {
    const testConnection = async () => {
      try {
        await getDocFromServer(doc(db, 'test', 'connection'));
      } catch (error) {
        if (error instanceof Error && error.message.includes('the client is offline')) {
          console.error("Please check your Firebase configuration.");
        }
      }
    };
    testConnection();
  }, []);

  // Data Listeners
  useEffect(() => {
    if (!user) return;

    const unsubFarmers = onSnapshot(collection(db, 'farmers'), (snap) => {
      setFarmers(snap.docs.map(d => ({ ...d.data(), id: d.id } as Farmer)));
    }, (err) => handleFirestoreError(err, OperationType.LIST, 'farmers'));

    const unsubCollections = onSnapshot(query(collection(db, 'collections'), orderBy('timestamp', 'desc')), (snap) => {
      setCollections(snap.docs.map(d => ({ ...d.data(), id: d.id } as MilkCollection)));
    }, (err) => handleFirestoreError(err, OperationType.LIST, 'collections'));

    const unsubPayments = onSnapshot(query(collection(db, 'payments'), orderBy('timestamp', 'desc')), (snap) => {
      setPayments(snap.docs.map(d => ({ ...d.data(), id: d.id } as Payment)));
    }, (err) => handleFirestoreError(err, OperationType.LIST, 'payments'));

    return () => {
      unsubFarmers();
      unsubCollections();
      unsubPayments();
    };
  }, [user]);

  const handleLogin = async () => {
    const provider = new GoogleAuthProvider();
    try {
      await signInWithPopup(auth, provider);
    } catch (error) {
      console.error("Login failed:", error);
    }
  };

  const handleLogout = () => signOut(auth);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-blue-600 border-t-transparent rounded-full animate-spin"></div>
          <p className="text-slate-500 font-medium">Loading Mpaa Distributers...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#F8FAFC]">
        <div className="max-w-md w-full p-8 bg-white rounded-[32px] shadow-2xl shadow-blue-100/50 border border-slate-100">
          <div className="text-center mb-8">
            <div className="w-20 h-20 bg-blue-600 rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-lg shadow-blue-200">
              <Milk className="w-10 h-10 text-white" />
            </div>
            <h1 className="text-3xl font-bold text-slate-900 mb-2">Mpaa Distributers</h1>
            <p className="text-slate-500">Milk Collection & Management System</p>
          </div>
          <button 
            onClick={handleLogin}
            className="w-full py-4 bg-blue-600 text-white rounded-2xl font-bold flex items-center justify-center gap-3 hover:bg-blue-700 transition-all active:scale-[0.98] shadow-lg shadow-blue-100"
          >
            <img src="https://www.google.com/favicon.ico" className="w-5 h-5" alt="Google" />
            Sign in with Google
          </button>
        </div>
      </div>
    );
  }

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard': return <Dashboard farmers={farmers} collections={collections} payments={payments} />;
      case 'farmers': return <FarmerManagement farmers={farmers} isAdmin={profile?.role === 'admin'} />;
      case 'collections': return <CollectionManagement collections={collections} farmers={farmers} isAdmin={profile?.role === 'admin'} />;
      case 'payments': return <PaymentManagement payments={payments} farmers={farmers} collections={collections} isAdmin={profile?.role === 'admin'} />;
      case 'settings': return <SettingsPage profile={profile} />;
      default: return <Dashboard farmers={farmers} collections={collections} payments={payments} />;
    }
  };

  return (
    <ErrorBoundary>
      <div className="min-h-screen bg-[#F8FAFC] flex">
        {/* Sidebar */}
        <aside className={cn(
          "fixed inset-y-0 left-0 z-50 w-72 bg-white border-r border-slate-100 transition-transform duration-300 lg:translate-x-0 lg:static",
          !isSidebarOpen && "-translate-x-full"
        )}>
          <div className="h-full flex flex-col">
            <div className="p-8 flex items-center gap-4">
              <div className="w-10 h-10 bg-blue-600 rounded-xl flex items-center justify-center shadow-lg shadow-blue-100">
                <Milk className="w-6 h-6 text-white" />
              </div>
              <span className="font-bold text-xl text-slate-900">Mpaa Dist.</span>
            </div>

            <nav className="flex-1 px-4 space-y-2">
              <NavItem active={activeTab === 'dashboard'} onClick={() => setActiveTab('dashboard')} icon={<BarChart3 />} label="Dashboard" />
              <NavItem active={activeTab === 'farmers'} onClick={() => setActiveTab('farmers')} icon={<Users />} label="Farmers" />
              <NavItem active={activeTab === 'collections'} onClick={() => setActiveTab('collections')} icon={<Milk />} label="Collections" />
              <NavItem active={activeTab === 'payments'} onClick={() => setActiveTab('payments')} icon={<CreditCard />} label="Payments" />
              <NavItem active={activeTab === 'settings'} onClick={() => setActiveTab('settings')} icon={<Settings />} label="Settings" />
            </nav>

            <div className="p-4 border-t border-slate-100">
              <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-2xl mb-4">
                <img src={user.photoURL || ''} className="w-10 h-10 rounded-xl" alt="User" />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-bold text-slate-900 truncate">{user.displayName}</p>
                  <p className="text-xs text-slate-500 truncate capitalize">{profile?.role}</p>
                </div>
              </div>
              <button 
                onClick={handleLogout}
                className="w-full flex items-center gap-3 p-3 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-2xl transition-colors"
              >
                <LogOut className="w-5 h-5" />
                <span className="font-semibold">Logout</span>
              </button>
            </div>
          </div>
        </aside>

        {/* Main Content */}
        <main className="flex-1 flex flex-col min-w-0">
          <header className="h-20 bg-white border-b border-slate-100 px-8 flex items-center justify-between sticky top-0 z-40">
            <button 
              onClick={() => setIsSidebarOpen(!isSidebarOpen)}
              className="lg:hidden p-2 text-slate-500 hover:bg-slate-50 rounded-xl"
            >
              {isSidebarOpen ? <X /> : <Menu />}
            </button>
            <h2 className="text-xl font-bold text-slate-900 capitalize">{activeTab}</h2>
            <div className="flex items-center gap-4">
              <button className="p-2 text-slate-500 hover:bg-slate-50 rounded-xl relative">
                <Bell className="w-5 h-5" />
                <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border-2 border-white"></span>
              </button>
            </div>
          </header>

          <div className="p-8 overflow-y-auto">
            <AnimatePresence mode="wait">
              <motion.div
                key={activeTab}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.2 }}
              >
                {renderContent()}
              </motion.div>
            </AnimatePresence>
          </div>
        </main>
      </div>
    </ErrorBoundary>
  );
}

function NavItem({ active, onClick, icon, label }: { active: boolean, onClick: () => void, icon: React.ReactNode, label: string }) {
  return (
    <button 
      onClick={onClick}
      className={cn(
        "w-full flex items-center gap-4 px-4 py-3.5 rounded-2xl font-semibold transition-all group",
        active 
          ? "bg-blue-600 text-white shadow-lg shadow-blue-100" 
          : "text-slate-500 hover:bg-slate-50 hover:text-slate-900"
      )}
    >
      <span className={cn("w-5 h-5", active ? "text-white" : "text-slate-400 group-hover:text-slate-900")}>
        {icon}
      </span>
      {label}
    </button>
  );
}

// --- Dashboard Component ---
function Dashboard({ farmers, collections, payments }: { farmers: Farmer[], collections: MilkCollection[], payments: Payment[] }) {
  const stats = useMemo(() => {
    const totalMilk = collections.reduce((acc, c) => acc + c.amount, 0);
    const totalPayments = payments.filter(p => p.status === 'paid').reduce((acc, p) => acc + p.amount, 0);
    const pendingPayments = payments.filter(p => p.status === 'pending').reduce((acc, p) => acc + p.amount, 0);
    
    // Chart Data
    const last7Days = Array.from({ length: 7 }, (_, i) => {
      const d = new Date();
      d.setDate(d.getDate() - i);
      return format(d, 'MMM dd');
    }).reverse();

    const chartData = last7Days.map(day => {
      const dayCollections = collections.filter(c => format(c.timestamp.toDate(), 'MMM dd') === day);
      return {
        name: day,
        liters: dayCollections.reduce((acc, c) => acc + c.amount, 0)
      };
    });

    return { totalMilk, totalPayments, pendingPayments, chartData };
  }, [collections, payments]);

  return (
    <div className="space-y-8">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard label="Total Farmers" value={farmers.length} icon={<Users className="text-blue-600" />} color="bg-blue-50" />
        <StatCard label="Total Milk (L)" value={stats.totalMilk.toFixed(1)} icon={<Milk className="text-emerald-600" />} color="bg-emerald-50" />
        <StatCard label="Paid Amount" value={`$${stats.totalPayments.toLocaleString()}`} icon={<CreditCard className="text-purple-600" />} color="bg-purple-50" />
        <StatCard label="Pending" value={`$${stats.pendingPayments.toLocaleString()}`} icon={<AlertCircle className="text-amber-600" />} color="bg-amber-50" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 bg-white p-8 rounded-[32px] border border-slate-100 shadow-sm">
          <div className="flex items-center justify-between mb-8">
            <h3 className="text-lg font-bold text-slate-900">Milk Collection Trend</h3>
            <select className="bg-slate-50 border-none rounded-xl px-4 py-2 text-sm font-semibold text-slate-600 focus:ring-2 focus:ring-blue-500">
              <option>Last 7 Days</option>
              <option>Last 30 Days</option>
            </select>
          </div>
          <div className="h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={stats.chartData}>
                <defs>
                  <linearGradient id="colorLiters" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2563eb" stopOpacity={0.1}/>
                    <stop offset="95%" stopColor="#2563eb" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#94a3b8', fontSize: 12 }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fill: '#94a3b8', fontSize: 12 }} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#fff', borderRadius: '16px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }}
                  itemStyle={{ color: '#2563eb', fontWeight: 'bold' }}
                />
                <Area type="monotone" dataKey="liters" stroke="#2563eb" strokeWidth={3} fillOpacity={1} fill="url(#colorLiters)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-white p-8 rounded-[32px] border border-slate-100 shadow-sm">
          <h3 className="text-lg font-bold text-slate-900 mb-6">Recent Collections</h3>
          <div className="space-y-6">
            {collections.slice(0, 5).map(c => {
              const farmer = farmers.find(f => f.id === c.farmerId);
              return (
                <div key={c.id} className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-slate-50 rounded-2xl flex items-center justify-center">
                    <Milk className="w-6 h-6 text-slate-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-bold text-slate-900 truncate">{farmer?.name || 'Unknown'}</p>
                    <p className="text-xs text-slate-500">{format(c.timestamp.toDate(), 'MMM dd, h:mm a')}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-bold text-blue-600">{c.amount}L</p>
                    <p className="text-xs text-slate-400">Q: {c.quality}</p>
                  </div>
                </div>
              );
            })}
          </div>
          <button className="w-full mt-8 py-3 text-sm font-bold text-blue-600 hover:bg-blue-50 rounded-xl transition-colors">
            View All Collections
          </button>
        </div>
      </div>
    </div>
  );
}

function StatCard({ label, value, icon, color }: { label: string, value: string | number, icon: React.ReactNode, color: string }) {
  return (
    <div className="bg-white p-6 rounded-[28px] border border-slate-100 shadow-sm flex items-center gap-5">
      <div className={cn("w-14 h-14 rounded-2xl flex items-center justify-center", color)}>
        {icon}
      </div>
      <div>
        <p className="text-sm font-semibold text-slate-500 mb-1">{label}</p>
        <p className="text-2xl font-bold text-slate-900">{value}</p>
      </div>
    </div>
  );
}

// --- Farmer Management ---
function FarmerManagement({ farmers, isAdmin }: { farmers: Farmer[], isAdmin: boolean }) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [search, setSearch] = useState('');
  const [editingFarmer, setEditingFarmer] = useState<Farmer | null>(null);

  const filteredFarmers = farmers.filter(f => 
    f.name.toLowerCase().includes(search.toLowerCase()) || 
    f.phone.includes(search)
  );

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    const data = {
      name: formData.get('name') as string,
      phone: formData.get('phone') as string,
      location: formData.get('location') as string,
      joinedAt: editingFarmer ? editingFarmer.joinedAt : Timestamp.now()
    };

    try {
      if (editingFarmer) {
        await updateDoc(doc(db, 'farmers', editingFarmer.id), data);
      } else {
        const id = `FARM-${Date.now()}`;
        await setDoc(doc(db, 'farmers', id), { ...data, id });
      }
      setIsModalOpen(false);
      setEditingFarmer(null);
    } catch (err) {
      handleFirestoreError(err, editingFarmer ? OperationType.UPDATE : OperationType.CREATE, 'farmers');
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this farmer?')) return;
    try {
      await deleteDoc(doc(db, 'farmers', id));
    } catch (err) {
      handleFirestoreError(err, OperationType.DELETE, 'farmers');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 w-5 h-5" />
          <input 
            type="text" 
            placeholder="Search farmers..." 
            className="w-full pl-12 pr-4 py-3.5 bg-white border border-slate-100 rounded-2xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none shadow-sm font-medium"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        {isAdmin && (
          <button 
            onClick={() => { setEditingFarmer(null); setIsModalOpen(true); }}
            className="w-full md:w-auto px-6 py-3.5 bg-blue-600 text-white rounded-2xl font-bold flex items-center justify-center gap-2 hover:bg-blue-700 transition-all shadow-lg shadow-blue-100"
          >
            <Plus className="w-5 h-5" />
            Add Farmer
          </button>
        )}
      </div>

      <div className="bg-white rounded-[32px] border border-slate-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-50/50 border-b border-slate-100">
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Farmer Name</th>
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Phone</th>
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Location</th>
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Joined</th>
                {isAdmin && <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider text-right">Actions</th>}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredFarmers.map(f => (
                <tr key={f.id} className="hover:bg-slate-50/50 transition-colors group">
                  <td className="px-8 py-5">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center font-bold">
                        {f.name[0]}
                      </div>
                      <span className="font-bold text-slate-900">{f.name}</span>
                    </div>
                  </td>
                  <td className="px-8 py-5 text-slate-600 font-medium">{f.phone}</td>
                  <td className="px-8 py-5 text-slate-600 font-medium">{f.location}</td>
                  <td className="px-8 py-5 text-slate-500 text-sm">{format(f.joinedAt.toDate(), 'MMM dd, yyyy')}</td>
                  {isAdmin && (
                    <td className="px-8 py-5 text-right">
                      <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button 
                          onClick={() => { setEditingFarmer(f); setIsModalOpen(true); }}
                          className="p-2 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button 
                          onClick={() => handleDelete(f.id)}
                          className="p-2 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal */}
      <AnimatePresence>
        {isModalOpen && (
          <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsModalOpen(false)}
              className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm"
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="relative bg-white w-full max-w-lg rounded-[32px] shadow-2xl p-8"
            >
              <h3 className="text-2xl font-bold text-slate-900 mb-6">{editingFarmer ? 'Edit Farmer' : 'Add New Farmer'}</h3>
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-700 px-1">Full Name</label>
                  <input name="name" defaultValue={editingFarmer?.name} required className="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-blue-500 outline-none font-medium" placeholder="e.g. John Doe" />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-700 px-1">Phone Number</label>
                  <input name="phone" defaultValue={editingFarmer?.phone} required className="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-blue-500 outline-none font-medium" placeholder="e.g. +254 700 000 000" />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-700 px-1">Location</label>
                  <input name="location" defaultValue={editingFarmer?.location} className="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-blue-500 outline-none font-medium" placeholder="e.g. Mpaa Village" />
                </div>
                <div className="flex gap-4 pt-4">
                  <button type="button" onClick={() => setIsModalOpen(false)} className="flex-1 py-4 text-slate-500 font-bold hover:bg-slate-50 rounded-2xl transition-colors">Cancel</button>
                  <button type="submit" className="flex-1 py-4 bg-blue-600 text-white font-bold rounded-2xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-100">
                    {editingFarmer ? 'Save Changes' : 'Add Farmer'}
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}

// --- Collection Management ---
function CollectionManagement({ collections, farmers, isAdmin }: { collections: MilkCollection[], farmers: Farmer[], isAdmin: boolean }) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [search, setSearch] = useState('');

  const filteredCollections = collections.filter(c => {
    const farmer = farmers.find(f => f.id === c.farmerId);
    return farmer?.name.toLowerCase().includes(search.toLowerCase()) || c.id.includes(search);
  });

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    const data = {
      farmerId: formData.get('farmerId') as string,
      amount: parseFloat(formData.get('amount') as string),
      quality: parseFloat(formData.get('quality') as string),
      timestamp: Timestamp.now(),
      collectedBy: auth.currentUser?.uid || ''
    };

    try {
      const id = `COLL-${Date.now()}`;
      await setDoc(doc(db, 'collections', id), { ...data, id });
      setIsModalOpen(false);
    } catch (err) {
      handleFirestoreError(err, OperationType.CREATE, 'collections');
    }
  };

  const exportToExcel = () => {
    const data = filteredCollections.map(c => {
      const farmer = farmers.find(f => f.id === c.farmerId);
      return {
        'Collection ID': c.id,
        'Farmer Name': farmer?.name || 'Unknown',
        'Amount (L)': c.amount,
        'Quality Score': c.quality,
        'Date': format(c.timestamp.toDate(), 'yyyy-MM-dd HH:mm:ss'),
        'Collected By': c.collectedBy
      };
    });

    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Collections");
    XLSX.writeFile(wb, `Milk_Collections_${format(new Date(), 'yyyy-MM-dd')}.xlsx`);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 w-5 h-5" />
          <input 
            type="text" 
            placeholder="Search collections..." 
            className="w-full pl-12 pr-4 py-3.5 bg-white border border-slate-100 rounded-2xl focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none shadow-sm font-medium"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div className="flex gap-3 w-full md:w-auto">
          <button 
            onClick={exportToExcel}
            className="flex-1 md:flex-none px-6 py-3.5 bg-white text-slate-700 border border-slate-100 rounded-2xl font-bold flex items-center justify-center gap-2 hover:bg-slate-50 transition-all shadow-sm"
          >
            <Download className="w-5 h-5" />
            Export
          </button>
          <button 
            onClick={() => setIsModalOpen(true)}
            className="flex-1 md:flex-none px-6 py-3.5 bg-blue-600 text-white rounded-2xl font-bold flex items-center justify-center gap-2 hover:bg-blue-700 transition-all shadow-lg shadow-blue-100"
          >
            <Plus className="w-5 h-5" />
            Record Milk
          </button>
        </div>
      </div>

      <div className="bg-white rounded-[32px] border border-slate-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-50/50 border-b border-slate-100">
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Date & Time</th>
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Farmer</th>
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Amount</th>
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Quality</th>
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredCollections.map(c => {
                const farmer = farmers.find(f => f.id === c.farmerId);
                return (
                  <tr key={c.id} className="hover:bg-slate-50/50 transition-colors">
                    <td className="px-8 py-5">
                      <p className="font-bold text-slate-900">{format(c.timestamp.toDate(), 'MMM dd, yyyy')}</p>
                      <p className="text-xs text-slate-500">{format(c.timestamp.toDate(), 'h:mm a')}</p>
                    </td>
                    <td className="px-8 py-5">
                      <span className="font-semibold text-slate-700">{farmer?.name || 'Unknown'}</span>
                    </td>
                    <td className="px-8 py-5">
                      <span className="font-bold text-blue-600">{c.amount} Liters</span>
                    </td>
                    <td className="px-8 py-5">
                      <div className="flex items-center gap-2">
                        <div className="w-16 h-2 bg-slate-100 rounded-full overflow-hidden">
                          <div className="h-full bg-emerald-500" style={{ width: `${c.quality * 10}%` }}></div>
                        </div>
                        <span className="text-xs font-bold text-slate-500">{c.quality}</span>
                      </div>
                    </td>
                    <td className="px-8 py-5">
                      <span className="px-3 py-1 bg-emerald-50 text-emerald-600 text-xs font-bold rounded-full">Recorded</span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal */}
      <AnimatePresence>
        {isModalOpen && (
          <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsModalOpen(false)}
              className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm"
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="relative bg-white w-full max-w-lg rounded-[32px] shadow-2xl p-8"
            >
              <h3 className="text-2xl font-bold text-slate-900 mb-6">Record Milk Collection</h3>
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-700 px-1">Select Farmer</label>
                  <select name="farmerId" required className="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-blue-500 outline-none font-medium">
                    <option value="">Choose a farmer...</option>
                    {farmers.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
                  </select>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="text-sm font-bold text-slate-700 px-1">Amount (Liters)</label>
                    <input name="amount" type="number" step="0.1" required className="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-blue-500 outline-none font-medium" placeholder="0.0" />
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-bold text-slate-700 px-1">Quality (1-10)</label>
                    <input name="quality" type="number" step="0.1" min="1" max="10" required className="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-blue-500 outline-none font-medium" placeholder="5.0" />
                  </div>
                </div>
                <div className="flex gap-4 pt-4">
                  <button type="button" onClick={() => setIsModalOpen(false)} className="flex-1 py-4 text-slate-500 font-bold hover:bg-slate-50 rounded-2xl transition-colors">Cancel</button>
                  <button type="submit" className="flex-1 py-4 bg-blue-600 text-white font-bold rounded-2xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-100">
                    Save Record
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}

// --- Payment Management ---
function PaymentManagement({ payments, farmers, collections, isAdmin }: { payments: Payment[], farmers: Farmer[], collections: MilkCollection[], isAdmin: boolean }) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [rate, setRate] = useState(45); // Default rate per liter

  const handleGeneratePayments = async () => {
    if (!isAdmin) return;
    const period = format(new Date(), 'yyyy-MM');
    
    // Calculate totals for each farmer for the current month
    const start = startOfMonth(new Date());
    const end = endOfMonth(new Date());

    const farmerTotals = farmers.map(f => {
      const farmerCollections = collections.filter(c => {
        const date = c.timestamp.toDate();
        return c.farmerId === f.id && isWithinInterval(date, { start, end });
      });
      return {
        farmerId: f.id,
        totalLiters: farmerCollections.reduce((acc, c) => acc + c.amount, 0)
      };
    });

    try {
      for (const total of farmerTotals) {
        if (total.totalLiters === 0) continue;
        
        // Check if payment already exists for this period
        const existing = payments.find(p => p.farmerId === total.farmerId && p.period === period);
        if (existing) continue;

        const id = `PAY-${Date.now()}-${total.farmerId}`;
        await setDoc(doc(db, 'payments', id), {
          id,
          farmerId: total.farmerId,
          amount: total.totalLiters * rate,
          period,
          status: 'pending',
          timestamp: Timestamp.now()
        });
      }
      setIsModalOpen(false);
      alert('Payments generated successfully!');
    } catch (err) {
      handleFirestoreError(err, OperationType.CREATE, 'payments');
    }
  };

  const handleMarkAsPaid = async (id: string) => {
    if (!isAdmin) return;
    try {
      await updateDoc(doc(db, 'payments', id), { status: 'paid' });
    } catch (err) {
      handleFirestoreError(err, OperationType.UPDATE, 'payments');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="bg-white px-6 py-3.5 rounded-2xl border border-slate-100 shadow-sm">
            <span className="text-sm font-bold text-slate-500 mr-3">Current Rate:</span>
            <span className="text-lg font-bold text-blue-600">${rate}/L</span>
          </div>
        </div>
        {isAdmin && (
          <button 
            onClick={() => setIsModalOpen(true)}
            className="w-full md:w-auto px-6 py-3.5 bg-blue-600 text-white rounded-2xl font-bold flex items-center justify-center gap-2 hover:bg-blue-700 transition-all shadow-lg shadow-blue-100"
          >
            <CreditCard className="w-5 h-5" />
            Generate Monthly Payments
          </button>
        )}
      </div>

      <div className="bg-white rounded-[32px] border border-slate-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-50/50 border-b border-slate-100">
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Period</th>
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Farmer</th>
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Amount</th>
                <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider">Status</th>
                {isAdmin && <th className="px-8 py-5 text-xs font-bold text-slate-500 uppercase tracking-wider text-right">Actions</th>}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {payments.map(p => {
                const farmer = farmers.find(f => f.id === p.farmerId);
                return (
                  <tr key={p.id} className="hover:bg-slate-50/50 transition-colors">
                    <td className="px-8 py-5 font-bold text-slate-900">{p.period}</td>
                    <td className="px-8 py-5 font-semibold text-slate-700">{farmer?.name || 'Unknown'}</td>
                    <td className="px-8 py-5 font-bold text-slate-900">${p.amount.toLocaleString()}</td>
                    <td className="px-8 py-5">
                      <span className={cn(
                        "px-3 py-1 text-xs font-bold rounded-full",
                        p.status === 'paid' ? "bg-emerald-50 text-emerald-600" : "bg-amber-50 text-amber-600"
                      )}>
                        {p.status.toUpperCase()}
                      </span>
                    </td>
                    {isAdmin && (
                      <td className="px-8 py-5 text-right">
                        {p.status === 'pending' && (
                          <button 
                            onClick={() => handleMarkAsPaid(p.id)}
                            className="text-sm font-bold text-blue-600 hover:bg-blue-50 px-4 py-2 rounded-xl transition-colors"
                          >
                            Mark as Paid
                          </button>
                        )}
                      </td>
                    )}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal */}
      <AnimatePresence>
        {isModalOpen && (
          <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsModalOpen(false)}
              className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm"
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="relative bg-white w-full max-w-lg rounded-[32px] shadow-2xl p-8"
            >
              <h3 className="text-2xl font-bold text-slate-900 mb-6">Generate Payments</h3>
              <div className="space-y-6">
                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-700 px-1">Rate per Liter ($)</label>
                  <input 
                    type="number" 
                    value={rate} 
                    onChange={(e) => setRate(parseFloat(e.target.value))}
                    className="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-blue-500 outline-none font-medium" 
                  />
                </div>
                <p className="text-sm text-slate-500">
                  This will calculate totals for all farmers for the current month ({format(new Date(), 'MMMM yyyy')}) and create pending payment records.
                </p>
                <div className="flex gap-4 pt-4">
                  <button type="button" onClick={() => setIsModalOpen(false)} className="flex-1 py-4 text-slate-500 font-bold hover:bg-slate-50 rounded-2xl transition-colors">Cancel</button>
                  <button onClick={handleGeneratePayments} className="flex-1 py-4 bg-blue-600 text-white font-bold rounded-2xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-100">
                    Generate Now
                  </button>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}

// --- Settings Page ---
function SettingsPage({ profile }: { profile: UserProfile | null }) {
  return (
    <div className="max-w-2xl space-y-8">
      <div className="bg-white p-8 rounded-[32px] border border-slate-100 shadow-sm">
        <h3 className="text-xl font-bold text-slate-900 mb-6">Profile Settings</h3>
        <div className="space-y-6">
          <div className="flex items-center gap-6">
            <img src={auth.currentUser?.photoURL || ''} className="w-20 h-20 rounded-3xl shadow-lg" alt="Profile" />
            <div>
              <p className="text-xl font-bold text-slate-900">{profile?.name}</p>
              <p className="text-slate-500">{profile?.email}</p>
              <span className="inline-block mt-2 px-3 py-1 bg-blue-50 text-blue-600 text-xs font-bold rounded-full capitalize">
                {profile?.role} Account
              </span>
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-4">
            <div className="space-y-2">
              <label className="text-sm font-bold text-slate-700 px-1">Display Name</label>
              <input disabled value={profile?.name} className="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl text-slate-500 cursor-not-allowed font-medium" />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-bold text-slate-700 px-1">Email Address</label>
              <input disabled value={profile?.email} className="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl text-slate-500 cursor-not-allowed font-medium" />
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white p-8 rounded-[32px] border border-slate-100 shadow-sm">
        <h3 className="text-xl font-bold text-slate-900 mb-6">System Preferences</h3>
        <div className="space-y-4">
          <div className="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
            <div>
              <p className="font-bold text-slate-900">Push Notifications</p>
              <p className="text-sm text-slate-500">Receive alerts for new collections</p>
            </div>
            <div className="w-12 h-6 bg-blue-600 rounded-full relative cursor-pointer">
              <div className="absolute right-1 top-1 w-4 h-4 bg-white rounded-full"></div>
            </div>
          </div>
          <div className="flex items-center justify-between p-4 bg-slate-50 rounded-2xl">
            <div>
              <p className="font-bold text-slate-900">Email Reports</p>
              <p className="text-sm text-slate-500">Weekly summary of distribution</p>
            </div>
            <div className="w-12 h-6 bg-slate-200 rounded-full relative cursor-pointer">
              <div className="absolute left-1 top-1 w-4 h-4 bg-white rounded-full"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
