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