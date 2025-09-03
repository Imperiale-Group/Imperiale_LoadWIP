page 79400 LoadWIP
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    AdditionalSearchTerms = 'caricamento,carrello,wip';
    AboutTitle = 'Caricamento Carrello';
    Caption = 'Caricamento Carrello';
    SourceTable = LoadWIP;
    Editable = true;
    InsertAllowed = true;

    layout
    {
        area(content)
        {
            field(Lot; Lot)
            {
                Caption = 'Lotto';
                ExtendedDatatype = Barcode;
            }
            field(SerialNo; SerialNo)
            {
                Caption = 'Seriale';
                ExtendedDatatype = Barcode;
            }
            field(Commessa; Commessa)
            {
                Caption = 'Commessa';
                ExtendedDatatype = Barcode;
                trigger OnValidate()
                begin
                    InsertRecord();
                end;
            }
        }
    }

    local procedure Refresh()
    begin
        Clear(Lot);
        Clear(SerialNo);
        Clear(Commessa);
    end;

    procedure InsertRecord()
    var
        NewRecord: Record "LoadWIP";
    begin
        if (Lot = '') or (SerialNo = '') or (Commessa = '') then
            Error('Tutti i campi devono essere compilati.');

        if Dialog.Confirm('Confermare?') then begin
            NewRecord.Init();
            NewRecord.Lot := Lot;
            NewRecord.SerialNo := SerialNo;
            NewRecord.Commessa := Commessa;
            NewRecord.DateTime := CurrentDateTime();
            NewRecord.Insert();
        end;
        Refresh();
    end;

    var
        Lot: Code[50];
        SerialNo: Code[50];
        Commessa: Code[50];
}