page 79400 LoadWIP_2
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    AdditionalSearchTerms = 'caricamento,carrello,wip';
    AboutTitle = 'Caricamento Carrello 2';
    Caption = 'Caricamento Carrello 2';
    SourceTable = LoadWIP;
    InsertAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            field(Commessa; Commessa)
            {
                Caption = 'Commessa';
                ExtendedDatatype = Barcode;

                trigger OnValidate()
                begin
                    Rec.Reset();
                    Rec.SetRange(Commessa, Commessa);
                    if Rec.FindSet() then
                        repeat
                            Rec.Validate(SerialNo);
                        until Rec.Next() = 0;
                    CurrPage.Update(false);
                end;
            }

            repeater(Group)
            {
                field(SerialNo; Rec.SerialNo)
                {
                    Caption = 'Seriale';
                    ExtendedDatatype = Barcode;
                    //Editable = Rec.SerialNo = '';
                }
                field(ItemNo; Rec.ItemNo)
                {
                    Caption = 'Nr. Articolo';
                    TableRelation = Item;
                }
                field(Description; GetItemDescription(Rec.ItemNo))
                {
                    Caption = 'Descrizione';
                    Editable = false;
                }
                field(Collo; Rec.Lot)
                {
                    Caption = 'Collo';
                    //Editable = Rec.Lot = '';
                    ExtendedDatatype = Barcode;

                    trigger OnValidate()
                    var
                        PackageNoInfo: Record "Package No. Information";
                        OlderPackageNo: Code[20];
                    begin
                        if Rec.Lot = 'CHK-SERIALE'
                        then begin
                            Rec.Lot := Rec.SerialNo;
                        end
                        else if Rec.Lot <> '' then begin
                            PackageNoInfo.Reset();
                            PackageNoInfo.SetRange("Package No.", Rec.Lot);
                            if PackageNoInfo.FindFirst() then begin
                                if (PackageNoInfo."Item No." <> Rec.ExpectedItemNo) and (Rec.ExpectedItemNo > '') then begin
                                    if not Dialog.Confirm('Il collo %1 dell''articolo %2 non corrisponde all''articolo previsto %3. Vuoi proseguire comunque?', false, Rec.Lot, PackageNoInfo."Item No.", Rec.ExpectedItemNo) then begin
                                        Rec.Lot := '';
                                        Rec.Modify();
                                        exit;
                                    end;
                                end;
                                // Controllo se esistono colli meno recenti
                                OlderPackageNo := ExistsOlderPackage(Rec.Lot);
                                if OlderPackageNo <> '' then begin
                                    if not Dialog.Confirm('Attenzione: è disponbile al prelievo un collo meno recente: %1. Vuoi proseguire comunque?', false, OlderPackageNo) then begin
                                        Rec.Lot := '';
                                        Rec.Modify();
                                        exit;
                                    end;
                                end;
                            end
                            else begin
                                if not Dialog.Confirm('Il collo %1 non è stato registrato. Vuoi proseguire comunque?', false, Rec.Lot) then begin
                                    Rec.Lot := '';
                                    Rec.Modify();
                                    exit;
                                end;
                            end;
                        end;
                        if Commessa > '' then
                            Rec.Commessa := Commessa;
                        Rec.DateTime := CurrentDateTime;
                        Rec.Modify();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Commessa, Commessa);
        CurrPage.Update(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Commessa := Commessa;
    end;

    var
        Commessa: Code[20];

    local procedure GetItemDescription(ItemNo: Code[20]): Text[100]
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            exit(Item.Description);
        exit('');
    end;

    local procedure ExistsOlderPackage(PackageNo: Code[20]): Code[20]
    var
        LoadWIP: Record "LoadWIP";
        SelectedPackage: Record "Package No. Information";
        SelectedPackageDate: Date;
        ILE: Record "Item Ledger Entry";
        StartDate: Date;
    begin
        StartDate := DMY2Date(1, 11, 2025); // data inizio check
        SelectedPackage.SetRange("Package No.", PackageNo);
        SelectedPackage.FindFirst();
        ILE.Reset();
        ILE.SetRange("Item No.", SelectedPackage."Item No.");
        ILE.SetRange("Entry Type", ILE."Entry Type"::"Positive Adjmt.");
        ILE.SetRange("Package No.", SelectedPackage."Package No.");
        if ILE.FindFirst() then
            SelectedPackageDate := ILE."Posting Date"
        else
            exit('');

        ILE.Reset();
        ILE.SetRange("Item No.", SelectedPackage."Item No.");
        ILE.SetRange("Entry Type", ILE."Entry Type"::"Positive Adjmt.");
        ILE.SetRange("Posting Date", StartDate, SelectedPackageDate - 1);
        ILE.SetCurrentKey("Package No.", "Posting Date");
        ILE.SetAscending("Posting Date", true);
        if ILE.FindSet() then
            repeat
                LoadWIP.Reset();
                LoadWIP.SetRange(Lot, ILE."Package No.");
                if LoadWIP.Count < ILE.Quantity then
                    exit(ILE."Package No.");
            until ILE.Next() = 0;
        exit('');
    end;
}