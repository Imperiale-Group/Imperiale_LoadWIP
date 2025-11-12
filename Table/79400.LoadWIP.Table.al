table 79400 LoadWIP
{

    fields
    {
        field(1; Lot; Code[50])
        {
            Caption = 'Lot';
        }
        field(2; SerialNo; Code[50])
        {
            Caption = 'Serial No.';
            trigger OnValidate()
            var
                Item: Record Item;
                SNInfo: Record "Serial No. Information";
                PackageInfo: Record "Package No. Information";
            begin
                SNInfo.Reset();
                SNInfo.SetRange("Serial No.", Rec.SerialNo);
                //SNInfo.SetRange("Job Number", Commessa);
                SNInfo.SetFilter("Variant Code", '<>%1', '');
                if SNInfo.FindFirst() then begin
                    Rec.ItemNo := SNInfo."Item No.";
                    //Rec.Modify();
                end;
            end;

        }
        field(3; Commessa; Code[50])
        {
            Caption = 'Commessa';
            //TableRelation = "Sales Header"."Lamborghini Order Code Ext";
        }
        field(4; DateTime; DateTime)
        {
            Caption = 'Data Carico';
        }
        field(5; ItemNo; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }

    }

    keys
    {
        key(PK; SerialNo)
        {
        }
    }
}