page 79401 "Sales Line Reservation"
{
    ApplicationArea = All;
    PageType = Worksheet;
    UsageCategory = Tasks;
    SourceTable = "Sales Line";
    SourceTableTemporary = true;
    ModifyAllowed = false;
    Caption = 'Associazione seriale a commessa';
    SourceTableView = sorting("Document No.", "Line No.");

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
                    UpdateFilters();
                end;

            }

            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    Caption = 'Nr. Articolo';
                }
                field(Description; Rec."Description")
                {
                    Caption = 'Descrizione';
                }
                field("TrackingSpecs"; 'Info Tracciabilità')
                {
                    Caption = 'Info Tracciabilità';

                    trigger OnDrillDown()
                    var
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
        }
    }

    var
        Commessa: Code[20];
        SalesHeader: Record "Sales Header";
        SerialNo: Code[50];

    trigger OnOpenPage()
    begin
        UpdateFilters();
    end;

    local procedure UpdateFilters()
    var
        ReservationEntry: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
    begin
        Rec.DeleteAll();
        SalesHeader.Reset();
        SalesHeader.SetRange("External Document No.", Commessa);
        if SalesHeader.FindFirst() then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.Setrange("Document Type", SalesHeader."Document Type");
            if SalesLine.FindSet() then
                repeat
                    if not HasReservation(SalesLine) then begin
                        Rec := SalesLine;
                        Rec.Insert();
                    end;
                until SalesLine.Next() = 0
        end;
        CurrPage.Update(false);
    end;

    local procedure HasReservation(var SalesLine: Record "Sales Line"): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        ReservationEntry.SetRange("Item Tracking", ReservationEntry."Item Tracking"::"Serial No.");
        exit(ReservationEntry.Count = SalesLine.Quantity);
    end;
}