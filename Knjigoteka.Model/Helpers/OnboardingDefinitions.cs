using System.Collections.Generic;
using System.Linq;

namespace Knjigoteka.Model.Helpers
{
    public static class OnboardingDefinitions
    {
        // Tutorial codes
        public const string SalesTutorialOpenModuleCode = "sales_tutorial_open_module";
        public const string SalesTutorialSearchCode = "sales_tutorial_search";
        public const string SalesTutorialAddToCartCode = "sales_tutorial_add_to_cart";
        public const string SalesTutorialAvailabilityCode = "sales_tutorial_availability";
        public const string SalesTutorialFinalizeSaleCode = "sales_tutorial_finalize_sale";
        public const string BooksTutorialOpenModuleCode = "books_tutorial_open_module";
        public const string BorrowingTutorialOpenModuleCode = "borrowing_tutorial_open_module";
        public const string ReservationsTutorialFindCode = "reservations_tutorial_open_module";

        // Mission codes
        public const string SalesMissionBasicSale = "sales_mission_basic_sale";
        public const string SalesMissionMultiSale = "sales_mission_multi_sale";
        public const string SalesMissionCheckAvailability = "sales_mission_check_availability";
        public const string SalesMissionQuantityAvailability = "sales_mission_quantity_availability";
        public const string BooksMissionRestockTwoCopies = "books_mission_restock_two_copies";
        public const string BorrowingMissionMarkReturnedCode = "borrowing_mission_mark_returned";
        public const string ReservationsMissionMarkDoneCode = "reservations_mission_mark_done";

        public static readonly List<OnboardingItemDefinition> Items = new()
        {
            // ---- TUTORIJALI – prodaja ----

            new OnboardingItemDefinition
            {
                Code = SalesTutorialOpenModuleCode,
                Name = "Uvod u modul „Prodaja“",
                Description = "Kratki tutorijal u kojem učiš gdje se nalazi i kako se otvara modul „Prodaja“.",
                ItemType = OnboardingItemType.Tutorial,
                Order = 1
            },
            new OnboardingItemDefinition
            {
                Code = SalesTutorialSearchCode,
                Name = "Pretraga knjiga",
                Description = "Nauči kako pronaći željenu knjigu koristeći polje za pretragu u modulu „Prodaja“.",
                ItemType = OnboardingItemType.Tutorial,
                Order = 2,
                RequiredItemCodes = new List<string> { SalesTutorialOpenModuleCode }
            },
            new OnboardingItemDefinition
            {
                Code = SalesTutorialAddToCartCode,
                Name = "Dodavanje knjiga u korpu",
                Description = "Korak po korak dodaješ knjige u korpu i upoznaješ se s radom sa količinama.",
                ItemType = OnboardingItemType.Tutorial,
                Order = 3,
                RequiredItemCodes = new List<string> { SalesTutorialSearchCode }
            },
            new OnboardingItemDefinition
            {
                Code = SalesTutorialAvailabilityCode,
                Name = "Provjera dostupnosti po poslovnicama",
                Description = "Učiš kako otvoriti prikaz dostupnosti knjige i provjeriti stanje u svim poslovnicama.",
                ItemType = OnboardingItemType.Tutorial,
                Order = 4,
                RequiredItemCodes = new List<string> { SalesTutorialAddToCartCode }
            },
            new OnboardingItemDefinition
            {
                Code = SalesTutorialFinalizeSaleCode,
                Name = "Završetak prodaje iz korpe",
                Description = "Tutorijal koji te vodi kroz pregled korpe i finalizaciju prodaje.",
                ItemType = OnboardingItemType.Tutorial,
                Order = 5,
                RequiredItemCodes = new List<string> { SalesTutorialAvailabilityCode }
            },

            // ---- MISIJE – prodaja ----
            new OnboardingItemDefinition
            {
                Code = SalesMissionBasicSale,
                Name = "Prva prodaja",
                Description = "Kupac dolazi u knjižaru i želi kupiti jedan primjerak knjige \"Na Drini ćuprija\". "
                              + "Tvoj zadatak je da pronađeš knjigu, dodaš je u korpu i završiš prodaju.",
                ItemType = OnboardingItemType.Mission,
                Order = 6,
                RequiredItemCodes = new List<string> { SalesTutorialFinalizeSaleCode }
            },
            new OnboardingItemDefinition
            {
                Code = SalesMissionMultiSale,
                Name = "Prodaja više knjiga",
                Description = "Kupac želi kupiti nekoliko različitih naslova u jednoj kupovini. "
                              + "Pronađi tražene knjige, dodaj ih u korpu i ispravno završi prodaju.",
                ItemType = OnboardingItemType.Mission,
                Order = 7,
                RequiredItemCodes = new List<string> { SalesMissionBasicSale }
            },
            new OnboardingItemDefinition
            {
                Code = SalesMissionCheckAvailability,
                Name = "Kupac traži knjigu \"Mali princ\"",
                Description = "Kupac te pita da li je knjiga \"Mali princ\" dostupna. "
                              + "Pronađi naslov i provjeri u kojim poslovnicama se trenutno nalazi.",
                ItemType = OnboardingItemType.Mission,
                Order = 8,
                RequiredItemCodes = new List<string> { SalesMissionMultiSale }
            },
            new OnboardingItemDefinition
            {
                Code = SalesMissionQuantityAvailability,
                Name = "Kupac traži 5 primjeraka \"Zločina i kazne\"",
                Description = "Kupac želi kupiti 5 primjeraka knjige \"Zločin i kazna\" za poklon. "
                              + "Tvoj zadatak je da pronađeš knjigu i provjeriš u kojoj poslovnici postoji tražena količina.",
                ItemType = OnboardingItemType.Mission,
                Order = 9,
                RequiredItemCodes = new List<string> { SalesMissionCheckAvailability }
            },

            // ---- Tutorijal + misija – Knjige ----
            new OnboardingItemDefinition
            {
                Code = BooksTutorialOpenModuleCode,
                Name = "Uvod u modul „Knjige“",
                Description = "Prvi ulazak u modul „Knjige“ – učiš gdje je pretraga i kako se prikazuju naslovi u tvojoj poslovnici.",
                ItemType = OnboardingItemType.Tutorial,
                Order = 10,
                RequiredItemCodes = new List<string> { SalesMissionQuantityAvailability }
            },
            new OnboardingItemDefinition
            {
                Code = BooksMissionRestockTwoCopies,
                Name = "Dopuna zaliha knjige",
                Description = "U tvojoj poslovnici neke knjige nisu dostupne. "
                              + "Pronađi jednu od njih i obezbjedi da 5 primjeraka ponovo bude dostupno čitaocima.",
                ItemType = OnboardingItemType.Mission,
                Order = 11,
                RequiredItemCodes = new List<string> { BooksTutorialOpenModuleCode }
            },

            // ---- Tutorijal + misija – Posudbe ----
            new OnboardingItemDefinition
            {
                Code = BorrowingTutorialOpenModuleCode,
                Name = "Uvod u modul „Posudbe“",
                Description = "Prvi put ulaziš u modul „Posudbe“ i učiš gdje je pretraga te kako se prikazuju aktivne posudbe.",
                ItemType = OnboardingItemType.Tutorial,
                Order = 12,
                RequiredItemCodes = new List<string> { BooksMissionRestockTwoCopies }
            },
            new OnboardingItemDefinition
            {
                Code = BorrowingMissionMarkReturnedCode,
                Name = "Vraćanje posuđene knjige",
                Description = "Član vraća posuđenu knjigu. "
                              + "Pronađi njegovu aktivnu posudbu i označi da je knjiga vraćena.",
                ItemType = OnboardingItemType.Mission,
                Order = 13,
                RequiredItemCodes = new List<string> { BorrowingTutorialOpenModuleCode }
            },

            // ---- Tutorijal + misija – Rezervacije ----
            new OnboardingItemDefinition
            {
                Code = ReservationsTutorialFindCode,
                Name = "Uvod u modul „Rezervacije“",
                Description = "Tutorijal koji te vodi do ekrana s rezervacijama i pokazuje kako da ih pretražuješ.",
                ItemType = OnboardingItemType.Tutorial,
                Order = 14,
                RequiredItemCodes = new List<string> { BorrowingMissionMarkReturnedCode }
            },
            new OnboardingItemDefinition
            {
                Code = ReservationsMissionMarkDoneCode,
                Name = "Preuzimanje rezervisane knjige",
                Description = "Korisnik dolazi po svoju ranije rezervisanu knjigu. "
                              + "Pronađi njegovu rezervaciju i označi da je knjiga preuzeta.",
                ItemType = OnboardingItemType.Mission,
                Order = 15,
                RequiredItemCodes = new List<string> { ReservationsTutorialFindCode }
            }
        };

        public static IEnumerable<OnboardingItemDefinition> Tutorials =>
            Items.Where(i => i.ItemType == OnboardingItemType.Tutorial);

        public static IEnumerable<OnboardingItemDefinition> Missions =>
            Items.Where(i => i.ItemType == OnboardingItemType.Mission);
    }
}
