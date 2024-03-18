public without sharing class DeleteCGShares {
    public static void removeExpiredSharingRecordsExtended(List<Contact_Group__Share> cgSharesToDelete){
        Database.delete(cgSharesToDelete);
    }
}