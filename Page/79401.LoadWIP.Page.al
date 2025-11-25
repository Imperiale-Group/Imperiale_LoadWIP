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
                    begin
                        PackageNoInfo.Reset();
                        PackageNoInfo.SetRange("Package No.", Rec.Lot);
                        if PackageNoInfo.FindFirst() then begin
                            if (PackageNoInfo."Item No." <> Rec.ExpectedItemNo) and (Rec.ExpectedItemNo > '') then begin
                                if not Dialog.Confirm('Il collo %1 dell''articolo %2 non corrisponde all''articolo previsto %3. Confermare?', false, Rec.Lot, PackageNoInfo."Item No.", Rec.ExpectedItemNo) then begin
                                    Rec.Lot := '';
                                    Rec.Modify();
                                    exit;
                                end;
                            end;
                        end
                        else begin
                            if not Dialog.Confirm('Il collo %1 non è stato registrato. Confermare?', false, Rec.Lot) then begin
                                Rec.Lot := '';
                                Rec.Modify();
                                exit;
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
}