page 79401 LoadWIP_2
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    AdditionalSearchTerms = 'caricamento,carrello,wip';
    AboutTitle = 'Caricamento Carrello 2';
    Caption = 'Caricamento Carrello 2';
    SourceTable = LoadWIP;
    InsertAllowed = true;

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
                        Item: Record Item;
                        SNInfo: Record "Serial No. Information";
                        PackageInfo: Record "Package No. Information";
                    begin
                        if CopyStr(Rec.Lot, 1, 2) = 'SN' then begin
                            SNInfo.Reset();
                            SNInfo.SetRange("Serial No.", Rec.Lot);
                            SNInfo.SetRange("Job Number", Commessa);
                            if SNInfo.FindFirst() then begin
                                Rec.ItemNo := SNInfo."Item No.";
                            end;
                        end
                        else begin
                            PackageInfo.Reset();
                            PackageInfo.SetRange("Package No.", Rec.Lot);
                            if PackageInfo.FindFirst() then begin
                                Rec.ItemNo := PackageInfo."Item No.";
                            end;
                        end;
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
}